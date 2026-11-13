## Atividade Brechó: curso #VemData

Tudo o que você precisa para refazer, sozinho, o case resolvido pelo mentor na aula ao vivo.

## O que você precisa instalado

- PostgreSQL
- DBeaver, conectado ao seu PostgreSQL (videoaula *Configurando o Ambiente*)

## Como usar este material

1. Abra o `01_Guia_do_aluno.md` e siga os passos em ordem, do Passo 0 ao Passo 7. Cada passo explica o comando e o motivo de ele ser escrito assim.
2. Antes do Passo 0, olhe a planilha original do brechó: online no Google Sheets (link abaixo) ou na cópia `planilha/brecho_planilha_vendas.xlsx`.
3. Abra os scripts no DBeaver na ordem em que o guia pede. Tente digitar os comandos antes de conferir com o script.
4. No fim do guia, a tabela "Confira seus resultados" mostra os números que você deve encontrar.

| Arquivo | Usado em |
| --- | --- |
| `scripts/brecho_01_planilha.sql` | Passo 0 (linhas 1–52) e Passo 1 (linhas 55–86) |
| `scripts/brecho_02_estrutura_e_carga.sql` | Passo 3 |
| `scripts/brecho_03_gabarito.sql` | Passos 4 a 7 (use para conferir suas respostas) |
| `planilha/brecho_planilha_vendas.xlsx` e `.csv` | A planilha original do case, para consulta |

**Planilha original no Google Sheets (aba `vendas`):**
https://docs.google.com/spreadsheets/d/1bH1KQhNo8Q9PKOJoOsg9Trnh33vq8Y08cww1GGLewCY/edit

**Deu algo errado?** Rode de novo o `brecho_01_planilha.sql` até a linha 52: ele apaga tudo e te devolve a um começo limpo. Depois refaça os passos seguintes.
