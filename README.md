# Sistema de registro e análise de operações de tráfego aéreo na aviação geral

Projeto final da disciplina de Banco de Dados do curso de Engenharia da Computação da AFYA Centro Universitário (6º período). O projeto consiste em um banco de dados relacional em MySQL, escrito em SQL puro, para o registro e a análise de operações de tráfego aéreo na aviação geral, com escopo restrito a aeronaves leves monomotoras usadas em instrução, passeio, voo particular e traslado. Os dados se concentram em Minas Gerais, com alguns aeródromos de São Paulo, Rio de Janeiro e Goiás usados em navegações e traslados.

O banco `trafego_aereo` tem 12 tabelas normalizadas até a terceira forma normal: aeródromos brasileiros reais e suas pistas, operadores (aeroclubes, escolas de aviação e proprietários particulares), modelos de aeronave, aeronaves, pilotos, setores do espaço aéreo, voos, tripulação de cada voo, travessias de setores, ocorrências e planos de voo. O esquema contém relacionamentos 1:1, 1:N e N:N, chaves estrangeiras com ações referenciais explícitas e restrições NOT NULL, UNIQUE, CHECK e DEFAULT. A massa de dados tem 367 registros, com no mínimo 15 por tabela.

## Integrantes

- Pedro Henrique Cardoso Maia
- Daniel Lemos Pinheiro Barbosa

Professor: Evandro José de Oliveira Junior

## Estrutura do repositório

```
README.md                       descrição do projeto e instruções de uso
sql/01_banco.sql                criação do banco, das tabelas e inserção dos dados
sql/02_consultas.sql            consultas SQL comentadas
docs/relatorio_tecnico.md       relatório técnico completo
docs/modelagem.md               modelagem lógica e física, regras de negócio e normalização
docs/dicionario_de_dados.md     dicionário de dados
docs/saidas_consultas.md        saídas reais das consultas
docs/img/der.mmd                fonte do diagrama entidade-relacionamento (Mermaid)
docs/img/der.png                imagem do diagrama entidade-relacionamento
```

## Requisitos

MySQL 8.0.16 ou superior. As restrições CHECK só são aplicadas pelo MySQL a partir dessa versão.

## Como executar

Os comandos abaixo devem ser executados a partir da pasta raiz do repositório.

1. Importar o banco. O script exclui o banco `trafego_aereo` se ele já existir, recria as tabelas e insere os dados; pode ser executado mais de uma vez.

   ```
   mysql -u root -p --default-character-set=utf8mb4 < sql/01_banco.sql
   ```

2. Executar as consultas.

   ```
   mysql -u root -p --default-character-set=utf8mb4 --table trafego_aereo < sql/02_consultas.sql
   ```

No MySQL Workbench, abra cada arquivo pelo menu File, opção Open SQL Script, e execute o script completo, primeiro `sql/01_banco.sql` e depois `sql/02_consultas.sql`.

Com Docker, usando a imagem oficial `mysql:8.0` (substitua `senha` por uma senha de sua escolha):

```
docker run --name bd_trafego -e MYSQL_ROOT_PASSWORD=senha -p 3306:3306 -d mysql:8.0
docker exec -i bd_trafego mysql -uroot -psenha --default-character-set=utf8mb4 < sql/01_banco.sql
docker exec -i bd_trafego mysql -uroot -psenha --default-character-set=utf8mb4 --table trafego_aereo < sql/02_consultas.sql
```

Aguarde alguns segundos após o `docker run` para que o servidor termine de inicializar antes de importar o banco.

## Documentação

O relatório técnico, com domínio, regras de negócio, diagrama, dicionário de dados, normalização, catálogo de consultas e instruções de execução, está em [docs/relatorio_tecnico.md](docs/relatorio_tecnico.md).
