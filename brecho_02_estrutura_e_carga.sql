-- =====================================================================
-- CASE BRECHÓ SEGUNDA CHANCE — Script 02: estrutura normalizada + carga
-- Pré-requisito: brecho_01_planilha.sql já executado.
--
-- Passo 3 da aula. O mentor escreve o DDL ao vivo e a turma replica;
-- este arquivo é a versão de referência (gabarito do modelo físico).
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE A — DDL: CREATE TABLE (modelo físico)
-- Ordem importa: primeiro as tabelas "pai", depois as que têm FK.
-- ---------------------------------------------------------------------

CREATE TABLE brecho.clientes (
    id_cliente     SERIAL PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,          -- integridade: um cadastro por e-mail
    cidade         VARCHAR(60),
    uf             CHAR(2),
    data_cadastro  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 1FN: telefone era multivalorado (vários numa célula) -> tabela própria (1:N)
CREATE TABLE brecho.telefones_cliente (
    id_telefone  SERIAL PRIMARY KEY,
    id_cliente   INT NOT NULL REFERENCES brecho.clientes(id_cliente),
    numero       VARCHAR(20) NOT NULL
);

-- 3FN: categoria se repetia como texto em cada produto -> tabela própria
CREATE TABLE brecho.categorias (
    id_categoria  SERIAL PRIMARY KEY,
    nome          VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE brecho.produtos (
    id_produto    SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    id_categoria  INT NOT NULL REFERENCES brecho.categorias(id_categoria),
    tamanho       VARCHAR(5),
    preco         NUMERIC(10,2) NOT NULL CHECK (preco > 0),
    estoque       INT NOT NULL DEFAULT 1 CHECK (estoque >= 0)
);

CREATE TABLE brecho.pedidos (
    id_pedido    INT PRIMARY KEY,                          -- mantém o número que o cliente já conhece
    id_cliente   INT NOT NULL REFERENCES brecho.clientes(id_cliente),
    data_pedido  DATE NOT NULL
);

-- N:N entre pedidos e produtos -> tabela associativa com chave composta.
-- 2FN: o NOME do produto depende só de id_produto (dependência parcial),
-- por isso ele fica em produtos. Já quantidade e preco_unitario dependem
-- da chave inteira (este produto, NESTE pedido) e ficam aqui.
CREATE TABLE brecho.itens_pedido (
    id_pedido       INT NOT NULL REFERENCES brecho.pedidos(id_pedido),
    id_produto      INT NOT NULL REFERENCES brecho.produtos(id_produto),
    quantidade      INT NOT NULL CHECK (quantidade > 0),
    preco_unitario  NUMERIC(10,2) NOT NULL,                -- preço praticado na venda (histórico)
    PRIMARY KEY (id_pedido, id_produto)
);

-- Índice na FK mais consultada (aula "Componentes e Arquitetura")
CREATE INDEX idx_pedidos_cliente ON brecho.pedidos(id_cliente);

-- ---------------------------------------------------------------------
-- PARTE B — Carga: da planilha (staging) para as tabelas normalizadas

-- ---------------------------------------------------------------------

-- Clientes: um por e-mail. Se a planilha divergir (ex.: "canoas/rs"),
-- vale o registro mais recente, padronizado com INITCAP/UPPER.
INSERT INTO brecho.clientes (nome, email, cidade, uf, data_cadastro)
SELECT DISTINCT ON (cliente_email)
       cliente_nome,
       cliente_email,
       INITCAP(TRIM(SPLIT_PART(cliente_cidade_uf, '/', 1))),
       UPPER(TRIM(SPLIT_PART(cliente_cidade_uf, '/', 2))),
       MIN(CAST(data_pedido AS DATE)) OVER (PARTITION BY cliente_email)
FROM brecho.planilha_vendas
ORDER BY cliente_email, CAST(data_pedido AS DATE) DESC;

-- Telefones: quebra "51 99911-2233; 51 98822-3344" em uma linha por número
INSERT INTO brecho.telefones_cliente (id_cliente, numero)
SELECT DISTINCT c.id_cliente, TRIM(t.numero)
FROM brecho.planilha_vendas p
JOIN brecho.clientes c ON c.email = p.cliente_email
CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(p.cliente_telefones, ';') AS t(numero)
WHERE p.cliente_telefones IS NOT NULL;

INSERT INTO brecho.categorias (nome)
SELECT DISTINCT categoria FROM brecho.planilha_vendas ORDER BY categoria;

-- Produtos: preço atual = último preço praticado; estoque inicial de exemplo
INSERT INTO brecho.produtos (nome, id_categoria, tamanho, preco, estoque)
SELECT DISTINCT ON (p.produto)
       p.produto, cat.id_categoria, p.tamanho, CAST(p.preco AS NUMERIC(10,2)),
       CASE WHEN p.produto = 'Camiseta básica branca' THEN 10 ELSE 1 END
FROM brecho.planilha_vendas p
JOIN brecho.categorias cat ON cat.nome = p.categoria
ORDER BY p.produto, CAST(p.data_pedido AS DATE) DESC;

INSERT INTO brecho.pedidos (id_pedido, id_cliente, data_pedido)
SELECT DISTINCT CAST(p.pedido AS INT), c.id_cliente, CAST(p.data_pedido AS DATE)
FROM brecho.planilha_vendas p
JOIN brecho.clientes c ON c.email = p.cliente_email;

INSERT INTO brecho.itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
SELECT CAST(p.pedido AS INT), pr.id_produto, CAST(p.quantidade AS INT), CAST(p.preco AS NUMERIC(10,2))
FROM brecho.planilha_vendas p
JOIN brecho.produtos pr ON pr.nome = p.produto;

-- Conferência: a soma vendida tem que bater com a planilha
SELECT
  (SELECT SUM(CAST(preco AS NUMERIC) * CAST(quantidade AS INT)) FROM brecho.planilha_vendas) AS total_planilha,
  (SELECT SUM(preco_unitario * quantidade) FROM brecho.itens_pedido)                         AS total_banco;