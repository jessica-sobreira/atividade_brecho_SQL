-- =====================================================================
-- CASE BRECHÓ SEGUNDA CHANCE — Script 03: roteiro de comandos e consultas (Passos 4 a 7)
-- Pré-requisito: scripts 01 e 02 executados.
-- O mentor executa bloco a bloco, ao vivo, explicando antes de rodar.
-- Os números de card (2.1, 3.4, D1...) são os mesmos do plano de aula.
-- =====================================================================

-- =====================================================================
-- PASSO 4 — ALTER, DML e transação  |  PASSO 5 — SELECT e integridade
-- =====================================================================

-- PASSO 4 · CARD 2.1 (ALTER) — O time de logística quer acompanhar o status do pedido.
ALTER TABLE brecho.pedidos
  ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pago'
  CHECK (status IN ('pendente','pago','enviado','entregue','cancelado'));

-- CARD 2.2 (INSERT) — Duas clientes se cadastraram pelo app e ainda não compraram.
INSERT INTO brecho.clientes (nome, email, cidade, uf)
VALUES ('Gabriela Prado', 'gabi.prado@email.com', 'Pelotas', 'RS'),
       ('Helena Duarte',  'helena.d@email.com',   NULL,      NULL);   -- não informou cidade

-- ...e chegaram peças novas que ainda não venderam.
INSERT INTO brecho.produtos (nome, id_categoria, tamanho, preco, estoque)
VALUES ('Vestido curto de linho',  (SELECT id_categoria FROM brecho.categorias WHERE nome = 'Vestidos'),   'P',  59.90, 1),
       ('Cinto de couro trançado', (SELECT id_categoria FROM brecho.categorias WHERE nome = 'Acessórios'), 'U',  24.90, 2);

-- CARD 2.3 (UPDATE com WHERE) — Pedidos de outubro já foram entregues; 1010 está pendente.
UPDATE brecho.pedidos SET status = 'entregue' WHERE data_pedido < '2026-11-01';
UPDATE brecho.pedidos SET status = 'enviado'  WHERE id_pedido IN (1007, 1008, 1009);
UPDATE brecho.pedidos SET status = 'pendente' WHERE id_pedido = 1010;

-- Promoção: acessórios com 10% de desconto
UPDATE brecho.produtos
SET preco = ROUND(preco * 0.90, 2)
WHERE id_categoria = (SELECT id_categoria FROM brecho.categorias WHERE nome = 'Acessórios');

-- CARD 2.4 (DELETE + transação) — "E se eu esquecer o WHERE?"
-- Rode bloco a bloco no DBeaver (modo de commit manual ou BEGIN explícito).
BEGIN;
  DELETE FROM brecho.telefones_cliente;              -- sem WHERE: apaga TUDO
  SELECT COUNT(*) AS telefones_restantes FROM brecho.telefones_cliente;   -- 0 :(
ROLLBACK;                                              -- Atomicidade (ACID) salvou o dia
SELECT COUNT(*) AS telefones_depois_do_rollback FROM brecho.telefones_cliente;


--PARAMOS AQUI

-- Agora do jeito certo: a Helena pediu para excluir o próprio cadastro (LGPD)
DELETE FROM brecho.clientes WHERE email = 'helena.d@email.com';
-- (reinsere para usarmos no LEFT JOIN e no COALESCE dos Passos 6 e 7)
INSERT INTO brecho.clientes (nome, email) VALUES ('Helena Duarte', 'helena.d@email.com');

-- PASSO 5 · CARD 2.5 (SELECT + WHERE + ORDER BY) — Clientes do RS em ordem alfabética
SELECT nome, cidade, uf
FROM brecho.clientes
WHERE uf = 'RS'
ORDER BY nome;

-- CARD 2.6 (LIKE / IS NULL / LIMIT)
SELECT nome, preco FROM brecho.produtos
WHERE nome ILIKE '%camiseta%' AND preco < 50
ORDER BY preco;

SELECT nome, email FROM brecho.clientes WHERE cidade IS NULL;

SELECT nome, preco FROM brecho.produtos ORDER BY preco DESC LIMIT 3;

-- CARD 2.7 (GROUP BY + HAVING para integridade) — Na planilha, algum e-mail
-- aparece com mais de uma cidade? (a anomalia que a normalização resolveu)
SELECT cliente_email, COUNT(DISTINCT cliente_cidade_uf) AS versoes_da_cidade
FROM brecho.planilha_vendas
GROUP BY cliente_email
HAVING COUNT(DISTINCT cliente_cidade_uf) > 1;

-- =====================================================================
-- PASSO 6 — JOINs e agregações  |  PASSO 7 — CASE, subquery, CTE e VIEW
-- =====================================================================

-- PASSO 6 · CARD 3.1 (INNER JOIN) — Lista de pedidos com nome do cliente, para o suporte
SELECT p.id_pedido, p.data_pedido, c.nome AS cliente, p.status
FROM brecho.pedidos p
INNER JOIN brecho.clientes c ON c.id_cliente = p.id_cliente
ORDER BY p.data_pedido DESC;

-- CARD 3.2 (LEFT JOIN) — Marketing: quem se cadastrou e nunca comprou?
SELECT c.nome, c.email
FROM brecho.clientes c
LEFT JOIN brecho.pedidos p ON p.id_cliente = c.id_cliente
WHERE p.id_pedido IS NULL;

-- ...e quais peças nunca venderam? (mesma lógica, outra tabela)
SELECT pr.nome, pr.preco
FROM brecho.produtos pr
LEFT JOIN brecho.itens_pedido i ON i.id_produto = pr.id_produto
WHERE i.id_pedido IS NULL;

-- CARD 3.3 (agregadas) — Números do mês para a reunião de sexta
SELECT COUNT(DISTINCT id_pedido)          AS pedidos,
       SUM(quantidade * preco_unitario)   AS faturamento,
       MIN(preco_unitario)                AS menor_item,
       MAX(preco_unitario)                AS maior_item,
       ROUND(AVG(preco_unitario), 2)      AS preco_medio_item
FROM brecho.itens_pedido;

-- CARD 3.4 (JOIN + GROUP BY) — Faturamento por categoria
SELECT cat.nome AS categoria,
       SUM(i.quantidade)                    AS pecas_vendidas,
       SUM(i.quantidade * i.preco_unitario) AS faturamento
FROM brecho.itens_pedido i
JOIN brecho.produtos   pr  ON pr.id_produto    = i.id_produto
JOIN brecho.categorias cat ON cat.id_categoria = pr.id_categoria
GROUP BY cat.nome
ORDER BY faturamento DESC;

-- PASSO 7 · CARD 3.5 (CASE + COALESCE + concatenação) — Programa de fidelidade
SELECT c.nome || ' (' || COALESCE(c.uf, '--') || ')'              AS cliente,
       COALESCE(c.cidade, 'Não informada')                         AS cidade,
       COALESCE(SUM(i.quantidade * i.preco_unitario), 0)           AS total_gasto,
       CASE
         WHEN SUM(i.quantidade * i.preco_unitario) >= 250 THEN 'Ouro'
         WHEN SUM(i.quantidade * i.preco_unitario) >= 100 THEN 'Prata'
         WHEN SUM(i.quantidade * i.preco_unitario) >  0   THEN 'Bronze'
         ELSE 'Sem compras'
       END                                                         AS nivel
FROM brecho.clientes c
LEFT JOIN brecho.pedidos      p ON p.id_cliente = c.id_cliente
LEFT JOIN brecho.itens_pedido i ON i.id_pedido  = p.id_pedido
GROUP BY c.id_cliente, c.nome, c.uf, c.cidade
ORDER BY total_gasto DESC;

-- =====================================================================
-- PASSO 7 (continuação) — Consultas de relatório, demonstradas pelo mentor
-- =====================================================================

-- D1 (subquery) — Peças com preço acima da média do catálogo
SELECT nome, preco
FROM brecho.produtos
WHERE preco > (SELECT AVG(preco) FROM brecho.produtos)
ORDER BY preco DESC;

-- D2 (CTE) — Ticket médio e quais pedidos ficaram acima dele
WITH total_por_pedido AS (
  SELECT id_pedido, SUM(quantidade * preco_unitario) AS total
  FROM brecho.itens_pedido
  GROUP BY id_pedido
)
SELECT id_pedido, total,
       ROUND((SELECT AVG(total) FROM total_por_pedido), 2) AS ticket_medio
FROM total_por_pedido
WHERE total > (SELECT AVG(total) FROM total_por_pedido)
ORDER BY total DESC;

-- D3 (CTE + JOIN + LIMIT) — Top 3 clientes por valor gasto
WITH gasto AS (
  SELECT p.id_cliente, SUM(i.quantidade * i.preco_unitario) AS total
  FROM brecho.pedidos p
  JOIN brecho.itens_pedido i ON i.id_pedido = p.id_pedido
  GROUP BY p.id_cliente
)
SELECT c.nome, g.total
FROM gasto g
JOIN brecho.clientes c ON c.id_cliente = g.id_cliente
ORDER BY g.total DESC
LIMIT 3;

-- D4 (bônus: VIEW + CAST) — Relatório pronto para o time de dados (OLAP leve)
CREATE OR REPLACE VIEW brecho.vw_vendas_detalhadas AS
SELECT p.id_pedido,
       CAST(p.data_pedido AS VARCHAR(10)) AS data_texto,
       c.nome   AS cliente,
       cat.nome AS categoria,
       pr.nome  AS produto,
       i.quantidade,
       i.preco_unitario,
       i.quantidade * i.preco_unitario AS subtotal,
       p.status
FROM brecho.itens_pedido i
JOIN brecho.pedidos    p   ON p.id_pedido     = i.id_pedido
JOIN brecho.clientes   c   ON c.id_cliente    = p.id_cliente
JOIN brecho.produtos   pr  ON pr.id_produto   = i.id_produto
JOIN brecho.categorias cat ON cat.id_categoria = pr.id_categoria;

SELECT categoria, SUM(subtotal) AS faturamento
FROM brecho.vw_vendas_detalhadas
WHERE status <> 'cancelado'
GROUP BY categoria
ORDER BY faturamento DESC;