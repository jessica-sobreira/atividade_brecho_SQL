-- =====================================================================
-- CASE BRECHÓ SEGUNDA CHANCE — Script 01: a planilha bruta (staging)
-- Banco: PostgreSQL | Ferramenta sugerida: DBeaver
--
-- Contexto: até hoje o brechó controla as vendas em UMA planilha só,
-- exportada do formulário de pedidos. Original no Google Sheets (aba "vendas"), recriada aqui como staging:
-- https://docs.google.com/spreadsheets/d/1bH1KQhNo8Q9PKOJoOsg9Trnh33vq8Y08cww1GGLewCY/edit
-- =====================================================================

DROP SCHEMA IF EXISTS brecho CASCADE;
CREATE SCHEMA brecho;

-- Tudo como texto, como chega de uma planilha exportada
-- (mesma estratégia da aula "Revisão de Normalização" do Projeto Final).

-- DDL (criação da tabela)
CREATE TABLE brecho.planilha_vendas (
    pedido            VARCHAR(10),
    data_pedido       VARCHAR(10),
    cliente_nome      VARCHAR(100),
    cliente_email     VARCHAR(100),
    cliente_telefones VARCHAR(100),   -- atenção: mais de um telefone na mesma célula
    cliente_cidade_uf VARCHAR(100),   -- atenção: cidade e UF juntas
    produto           VARCHAR(100),
    categoria         VARCHAR(50),
    tamanho           VARCHAR(5),
    preco             VARCHAR(10),
    quantidade        VARCHAR(5)
);

-- DML (comando para inserir dados)

INSERT INTO brecho.planilha_vendas VALUES
('1001','2026-10-02','Ana Souza','ana.souza@email.com','51 99911-2233; 51 98822-3344','Porto Alegre/RS','Jaqueta jeans vintage','Casacos','M','89.90','1'),
('1001','2026-10-02','Ana Souza','ana.souza@email.com','51 99911-2233; 51 98822-3344','Porto Alegre/RS','Óculos retrô','Acessórios','U','39.90','1'),
('1002','2026-10-05','Bruno Lima','bruno.lima@email.com','51 99733-4455','Canoas/RS','Tênis Converse All Star','Calçados','38','119.90','1'),
('1003','2026-10-09','Carla Mendes','carla.m@email.com','11 98123-4567','São Paulo/SP','Vestido floral midi','Vestidos','P','74.90','1'),
('1003','2026-10-09','Carla Mendes','carla.m@email.com','11 98123-4567','São Paulo/SP','Bolsa de couro caramelo','Acessórios','U','139.90','1'),
('1003','2026-10-09','Carla Mendes','carla.m@email.com','11 98123-4567','São Paulo/SP','Camiseta básica branca','Camisetas','M','29.90','2'),
('1004','2026-10-15','Ana Souza','ana.souza@email.com','51 99911-2233; 51 98822-3344','Porto Alegre/RS','Camiseta banda anos 90','Camisetas','G','49.90','1'),
('1005','2026-10-20','Diego Rocha','diego.rocha@email.com',NULL,'Porto Alegre/RS','Casaco de lã xadrez','Casacos','G','129.90','1'),
('1005','2026-10-20','Diego Rocha','diego.rocha@email.com',NULL,'Porto Alegre/RS','Camiseta básica branca','Camisetas','M','29.90','1'),
('1006','2026-10-28','Elisa Kato','elisa.kato@email.com','41 99654-3210; 41 3322-1100','Curitiba/PR','Bota de couro marrom','Calçados','37','159.90','1'),
('1006','2026-10-28','Elisa Kato','elisa.kato@email.com','41 99654-3210; 41 3322-1100','Curitiba/PR','Vestido preto longo','Vestidos','M','99.90','1'),
('1007','2026-11-02','Bruno Lima','bruno.lima@email.com','51 99733-4455','canoas/rs','Camiseta básica branca','Camisetas','M','29.90','1'),
('1008','2026-11-05','Fábio Nunes','fabio.n@email.com','51 99100-2030','Novo Hamburgo/RS','Camiseta básica branca','Camisetas','M','34.90','1'),
('1008','2026-11-05','Fábio Nunes','fabio.n@email.com','51 99100-2030','Novo Hamburgo/RS','Óculos retrô','Acessórios','U','39.90','1'),
('1009','2026-11-08','Carla Mendes','carla.m@email.com','11 98123-4567','São Paulo/SP','Casaco de lã xadrez','Casacos','G','129.90','1'),
('1010','2026-11-10','Elisa Kato','elisa.kato@email.com','41 99654-3210; 41 3322-1100','Curitiba/PR','Bolsa de couro caramelo','Acessórios','U','139.90','1'),
('1010','2026-11-10','Elisa Kato','elisa.kato@email.com','41 99654-3210; 41 3322-1100','Curitiba/PR','Camiseta básica branca','Camisetas','M','34.90','1');

-- Primeira olhada: quantas linhas? quantos pedidos de verdade?
SELECT * FROM brecho.planilha_vendas;
SELECT COUNT(*) AS linhas, COUNT(DISTINCT pedido) AS pedidos FROM brecho.planilha_vendas;

-- =====================================================================
-- PASSO 1 — Diagnóstico da planilha (rode uma consulta por vez, Ctrl+Enter)
-- Cada consulta revela um problema que a normalização vai resolver.
-- =====================================================================

-- 1) Redundância: os dados da Ana se repetem em 3 linhas
SELECT pedido, data_pedido, cliente_nome, cliente_cidade_uf
FROM brecho.planilha_vendas
WHERE cliente_email = 'ana.souza@email.com';

-- 2) Anomalia de atualização: a cidade do Bruno foi escrita de dois jeitos
SELECT DISTINCT pedido, cliente_cidade_uf
FROM brecho.planilha_vendas
WHERE cliente_email = 'bruno.lima@email.com';

-- 3) 1FN: mais de um telefone na mesma célula
SELECT DISTINCT cliente_nome, cliente_telefones
FROM brecho.planilha_vendas
WHERE cliente_telefones LIKE '%;%';

-- 4) Preço histórico: a mesma camiseta vendida a 29,90 e depois a 34,90
SELECT pedido, data_pedido, produto, preco
FROM brecho.planilha_vendas
WHERE produto = 'Camiseta básica branca'
ORDER BY data_pedido;

-- 5) 3FN: a categoria se repete como texto em cada produto
SELECT DISTINCT categoria, produto
FROM brecho.planilha_vendas
ORDER BY categoria, produto;

-- 6) Anomalia de exclusão: o pedido 1002 é o único registro do tênis
SELECT * FROM brecho.planilha_vendas WHERE pedido = '1002';