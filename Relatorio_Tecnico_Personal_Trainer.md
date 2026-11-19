# Relatório Técnico — Sistema de Gerenciamento para Personal Trainer

## 1. Capa e identificação

| | |
|---|---|
| **Título** | Sistema de Gerenciamento para Personal Trainer: modelagem, implementação e análise de um banco de dados relacional em MySQL |
| **Integrantes da dupla** | Nicolas Fernandes Bié e Gabriel Castro |
| **Disciplina** | Banco de Dados (Projeto Final) |
| **Curso** | Engenharia da Computação |
| **Instituição** | Afya Centro Universitário |
| **Orientador** | Prof. Evandro Junior |
| **Semestre** | 2º semestre de 2026 |
| **Local e ano** | Montes Claros, 2026 |
| **Banco de dados** | `personal_trainer_db` (MySQL 8.0.16 ou superior) |

## 2. Resumo executivo

Este trabalho apresenta a modelagem, a implementação e a análise de um banco de dados relacional para o gerenciamento de um serviço de personal trainer, desenvolvido em MySQL com uso exclusivo da linguagem SQL. O sistema reúne o cadastro de alunos e profissionais, o agendamento de aulas, a prescrição de planos de treino, o registro das execuções de exercícios, o acompanhamento de avaliações físicas e o controle financeiro das mensalidades. O esquema físico é composto por onze tabelas, treze chaves estrangeiras com políticas explícitas de ON DELETE e ON UPDATE, trinta e uma restrições CHECK e nove valores DEFAULT, normalizadas até a Terceira Forma Normal, com relacionamentos 1:1, 1:N e N:N. O banco foi povoado com dados fictícios, porém plausíveis, em quantidade mínima de quinze registros por tabela, de modo que todas as consultas retornassem resultados significativos. Foram elaboradas quinze consultas SQL, distribuídas entre consultas simples, consultas com junções e agregações e consultas de aprofundamento, que empregam subconsulta e junção externa. Para cada consulta, o documento registra a pergunta de negócio, o código e um exemplo de saída. Também são apresentados o diagrama entidade-relacionamento, o dicionário de dados, a justificativa de normalização e as instruções de execução do script. Conclui-se que o modelo atende aos requisitos da disciplina e às regras de negócio levantadas, preservando a integridade dos dados e o histórico das operações.

**Palavras-chave:** banco de dados relacional; MySQL; SQL; modelagem de dados; personal trainer.

## 3. Domínio e regras de negócio

### 3.1 Cenário

O banco de dados modelado atende a um profissional de educação física que atua como personal trainer, de forma autônoma ou em uma pequena equipe. Cada aluno possui dados de identificação e um perfil com objetivo físico, nível de experiência, restrições médicas, contato de emergência e frequência semanal desejada. As aulas são individuais: cada aula reúne um aluno e um personal, em data, horário e local definidos, e passa pelos estados agendada, realizada, cancelada ou faltou.

O personal elabora planos de treino personalizados, compostos por exercícios do catálogo, cada um com ordem, séries, repetições, carga sugerida e tempo de descanso. Os exercícios são classificados por grupo muscular. A cada execução real de um exercício pelo aluno, registra-se data, séries, repetições médias e carga, o que permite acompanhar a progressão. O personal também realiza avaliações físicas periódicas (peso, altura, percentual de gordura e circunferência da cintura) e o sistema controla as mensalidades de cada aluno, com vencimento, valor, forma de pagamento e situação.

### 3.2 Regras de negócio

O levantamento resultou em onze regras de negócio, listadas no Quadro 1 juntamente com o mecanismo do banco que garante cada uma.

**Quadro 1 – Regras de negócio e mecanismo de garantia no banco**

| **Código** | **Regra**                                                                                                                                                                 | **Garantia no banco**                                                                                                   |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| RN01       | Um aluno possui exatamente um perfil, e um perfil pertence a um único aluno (1:1).                                                                                        | Chave primária de PERFIL_ALUNO que é também chave estrangeira para ALUNO                                                |
| RN02       | CPF e e-mail são únicos para alunos e para personais. O CREF é único para personais.                                                                                      | Restrições UNIQUE                                                                                                       |
| RN03       | Um personal pode ministrar várias aulas. Cada aula tem um único personal e um único aluno (atendimento individual).                                                       | Chaves estrangeiras em AULA, ambas NOT NULL                                                                             |
| RN04       | Uma aula não pode terminar antes de começar. O status da aula é AGENDADA, REALIZADA, CANCELADA ou FALTOU e nasce como AGENDADA.                                           | CHECK em hora_fim e em status; DEFAULT em status                                                                        |
| RN05       | Um aluno pode ter vários planos de treino ao longo do tempo. Cada plano é elaborado por um personal e pertence a um aluno.                                                | Chaves estrangeiras em PLANO_TREINO; CHECK nas datas e no status                                                        |
| RN06       | Um plano contém vários exercícios, e um exercício pode aparecer em vários planos (N:N). No item ficam séries, repetições, carga sugerida, descanso e ordem.               | Tabela associativa ITEM_PLANO, com UNIQUE (id_plano, ordem) e UNIQUE (id_plano, id_exercicio)                           |
| RN07       | Todo exercício pertence a um grupo muscular principal. Um grupo muscular classifica vários exercícios.                                                                    | Chave estrangeira NOT NULL em EXERCICIO                                                                                 |
| RN08       | Cada execução de exercício feita pelo aluno vira um registro, formando a relação N:N entre aluno e exercício. O aluno pode repetir o mesmo exercício em datas diferentes. | Tabela associativa REGISTRO_TREINO, sem UNIQUE composto                                                                 |
| RN09       | As avaliações físicas são periódicas e feitas por um personal. Peso, altura e medidas devem ser positivos. O IMC não é armazenado, pois é calculável.                     | CHECK nas medidas; IMC calculado nas consultas                                                                          |
| RN10       | Cada mensalidade pertence a um aluno, tem vencimento, valor positivo e status PENDENTE, PAGO ou ATRASADO. Nasce como PENDENTE e só tem data de pagamento quando quitada.  | CHECK em valor, status e na combinação PAGO com data de pagamento; DEFAULT em status; UNIQUE (id_aluno, referencia_mes) |
| RN11       | Alunos e personais têm status ATIVO ou INATIVO. Dados históricos não são apagados em cascata: a inativação é lógica, por status.                                          | CHECK e DEFAULT em status; ON DELETE RESTRICT nas chaves que preservam o histórico                                      |

Fonte: elaborado pelos autores (2026).

### 3.3 Entidades

O esquema é formado por onze entidades, descritas no Quadro 2.

**Quadro 2 – Entidades do sistema e sua finalidade**

| **Nº** | **Entidade**     | **Finalidade**                                                                        |
|--------|------------------|---------------------------------------------------------------------------------------|
| 1      | PERSONAL_TRAINER | Cadastro dos profissionais que prestam o serviço.                                     |
| 2      | ALUNO            | Cadastro dos alunos atendidos.                                                        |
| 3      | PERFIL_ALUNO     | Informações complementares individuais do aluno (relacionamento 1:1).                 |
| 4      | GRUPO_MUSCULAR   | Classificação dos exercícios por grupo muscular.                                      |
| 5      | EXERCICIO        | Catálogo de exercícios.                                                               |
| 6      | PLANO_TREINO     | Planos de treinamento personalizados.                                                 |
| 7      | ITEM_PLANO       | Associação entre planos e exercícios (N:N), com séries, repetições, carga e descanso. |
| 8      | AULA             | Agendamento e controle das aulas.                                                     |
| 9      | AVALIACAO_FISICA | Avaliações físicas periódicas dos alunos.                                             |
| 10     | PAGAMENTO        | Controle financeiro das mensalidades.                                                 |
| 11     | REGISTRO_TREINO  | Histórico de execução dos exercícios (N:N entre aluno e exercício).                   |

Fonte: elaborado pelos autores (2026).

### 3.4 Relacionamentos e cardinalidades

**Quadro 3 – Relacionamentos e cardinalidades**

| **Relacionamento**                  | **Cardinalidade** | **Observação**                                                         |
|-------------------------------------|-------------------|------------------------------------------------------------------------|
| ALUNO — PERFIL_ALUNO                | 1:1               | O perfil usa a própria chave primária do aluno como chave estrangeira. |
| PERSONAL_TRAINER — AULA             | 1:N               | Um personal ministra muitas aulas; cada aula tem um só personal.       |
| ALUNO — AULA                        | 1:N               | Um aluno faz muitas aulas; cada aula atende um só aluno.               |
| ALUNO — PLANO_TREINO                | 1:N               | Um aluno tem vários planos ao longo do tempo.                          |
| PERSONAL_TRAINER — PLANO_TREINO     | 1:N               | Um personal elabora vários planos.                                     |
| ALUNO — AVALIACAO_FISICA            | 1:N               | Um aluno tem várias avaliações periódicas.                             |
| PERSONAL_TRAINER — AVALIACAO_FISICA | 1:N               | Um personal realiza várias avaliações.                                 |
| ALUNO — PAGAMENTO                   | 1:N               | Um aluno tem várias mensalidades.                                      |
| GRUPO_MUSCULAR — EXERCICIO          | 1:N               | Um grupo classifica vários exercícios.                                 |
| PLANO_TREINO — EXERCICIO            | N:N               | Resolvido pela tabela associativa ITEM_PLANO.                          |
| ALUNO — EXERCICIO                   | N:N               | Resolvido pela tabela associativa REGISTRO_TREINO.                     |

Fonte: elaborado pelos autores (2026).

### 3.5 Decisões de projeto

As principais decisões de modelagem foram as seguintes:

1)  **perfil separado do aluno (1:1):** dados de identificação ficam em ALUNO e dados de treino e saúde ficam em PERFIL_ALUNO, separando responsabilidades e protegendo os dados mais sensíveis;

2)  **objetivo físico somente no perfil:** o objetivo não é repetido em PLANO_TREINO, o que evita redundância;

3)  **personal fora de ALUNO:** como o aluno pode ter aulas com personais diferentes, por exemplo em substituições, o vínculo ocorre por AULA e PLANO_TREINO; uma chave estrangeira fixa em ALUNO seria rígida e geraria dependência transitiva;

4)  **REGISTRO_TREINO sem id_aula:** com id_aula e id_aluno na mesma tabela, o aluno seria determinado pela aula, uma dependência transitiva que fere a 3FN;

5)  **ITEM_PLANO com chave própria:** usa id_item_plano como chave substituta, com UNIQUE (id_plano, ordem) e UNIQUE (id_plano, id_exercicio);

6)  **atributos calculáveis não armazenados:** IMC, idade e total pago são calculados nas consultas.

## 4. Diagrama entidade-relacionamento (DER) e modelagem

### 4.1 Modelo lógico

O modelo lógico traduz as entidades em tabelas, cada uma com chave primária do tipo INT AUTO_INCREMENT, exceto PERFIL_ALUNO, cuja chave primária é herdada de ALUNO. Os tipos de dados foram escolhidos de acordo com o domínio: CHAR(11) para o CPF, DECIMAL para valores monetários e medidas, DATE e TIME para datas e horários, TINYINT e SMALLINT para contagens pequenas e VARCHAR com tamanhos compatíveis com o conteúdo. A estrutura completa, com tipos e restrições, está no dicionário de dados da Seção 5.

### 4.2 Diagrama entidade-relacionamento

A Figura 1 apresenta o DER do banco em notação pé de galinha (crow’s foot). Cada retângulo representa uma tabela, com nome, colunas, tipos e a indicação de chave primária (PK), chave estrangeira (FK) e restrição de unicidade (UQ). Nas linhas de relacionamento, o traço transversal indica o lado “um” e o símbolo em forma de pé de galinha indica o lado “muitos”.

**Figura 1 – Diagrama entidade-relacionamento do sistema de gerenciamento para personal trainer**

![DER do banco personal_trainer_db](imagens/DER_personal_trainer.png)

Legenda: PK = chave primária; FK = chave estrangeira; UQ = único; 1:1 e 1:N = cardinalidades.

Fonte: elaborado pelos autores (2026), a partir das tabelas, colunas e chaves estrangeiras do banco criado no MySQL.

### 4.3 Explicação dos relacionamentos

#### 4.3.1 Relacionamento 1:1

ALUNO e PERFIL_ALUNO se relacionam em 1:1. A chave primária de PERFIL_ALUNO é também chave estrangeira para ALUNO. Como uma chave primária não se repete, não existem dois perfis para o mesmo aluno, sem necessidade de uma restrição UNIQUE adicional.

#### 4.3.2 Relacionamentos 1:N

Em todos os relacionamentos 1:N a chave estrangeira fica no lado N, mantendo cada fato em um único lugar. GRUPO_MUSCULAR 1:N EXERCICIO é implementado com uma tabela própria, em vez de texto repetido em cada exercício, o que evita inconsistências de escrita e elimina redundância.

#### 4.3.3 Relacionamentos N:N

PLANO_TREINO N:N EXERCICIO é resolvido pela tabela associativa ITEM_PLANO, que guarda as informações próprias do vínculo: ordem, séries, repetições, carga e descanso. ALUNO N:N EXERCICIO é resolvido por REGISTRO_TREINO. Cada linha dessa tabela é uma execução real de um exercício em uma data, com carga e repetições, o que permite acompanhar a evolução de carga ao longo do tempo.

### 4.4 Políticas das chaves estrangeiras

Todas as chaves estrangeiras declaram ON DELETE e ON UPDATE de forma explícita. O Quadro 4 resume a política adotada e a razão de cada escolha. A atualização em cascata (ON UPDATE CASCADE) é usada em todas, enquanto a exclusão varia conforme a natureza do vínculo: em cascata quando a linha filha é parte da linha pai e não existe sozinha, e restrita quando a linha filha representa histórico que deve ser preservado (regra RN11).

**Quadro 4 – Políticas de ON DELETE e ON UPDATE das chaves estrangeiras**

| **Chave estrangeira**                                                     | **ON DELETE** | **ON UPDATE** | **Justificativa**                                                  |
|---------------------------------------------------------------------------|---------------|---------------|--------------------------------------------------------------------|
| PERFIL_ALUNO → ALUNO                                                      | CASCADE       | CASCADE       | O perfil é parte do aluno e não existe sozinho.                    |
| ITEM_PLANO → PLANO_TREINO                                                 | CASCADE       | CASCADE       | Os itens fazem parte do plano.                                     |
| ITEM_PLANO → EXERCICIO                                                    | RESTRICT      | CASCADE       | Não se apaga exercício que está em uso.                            |
| EXERCICIO → GRUPO_MUSCULAR                                                | RESTRICT      | CASCADE       | O catálogo deve continuar consistente.                             |
| PLANO_TREINO, AULA, AVALIACAO_FISICA, PAGAMENTO e REGISTRO_TREINO → ALUNO | RESTRICT      | CASCADE       | Preserva o histórico (RN11); a saída do aluno é feita pelo status. |
| PLANO_TREINO, AULA e AVALIACAO_FISICA → PERSONAL_TRAINER                  | RESTRICT      | CASCADE       | Preserva o histórico profissional.                                 |
| REGISTRO_TREINO → EXERCICIO                                               | RESTRICT      | CASCADE       | Preserva o histórico de execução.                                  |

Fonte: elaborado pelos autores (2026).

## 5. Dicionário de dados

Esta seção detalha cada tabela do esquema, com atributo, tipo, restrições e descrição. Nas colunas de restrições, PK indica chave primária, FK chave estrangeira, UQ restrição UNIQUE, NN NOT NULL e AI AUTO_INCREMENT. As restrições CHECK são descritas pela regra que impõem. A partir do Quadro 5 aparecem as onze tabelas, na ordem em que são criadas pelo script.

### 5.1 PERSONAL_TRAINER

**Quadro 5 – Dicionário de dados da tabela PERSONAL_TRAINER**

| **Atributo**  | **Tipo**     | **Restrições**                              | **Descrição**                                    |
|---------------|--------------|---------------------------------------------|--------------------------------------------------|
| id_personal   | INT          | PK, NN, AI                                  | Identificador único do profissional.             |
| nome          | VARCHAR(100) | NN                                          | Nome completo do personal trainer.               |
| cpf           | CHAR(11)     | UQ, NN, CHECK (11 dígitos numéricos)        | CPF, somente dígitos.                            |
| email         | VARCHAR(100) | UQ, NN                                      | E-mail de contato.                               |
| telefone      | VARCHAR(15)  | NN                                          | Telefone de contato.                             |
| cref          | VARCHAR(15)  | UQ, NN                                      | Registro no conselho profissional (CREF).        |
| especialidade | VARCHAR(60)  | Opcional                                    | Área de atuação do profissional.                 |
| valor_hora    | DECIMAL(8,2) | NN, CHECK (\> 0)                            | Valor cobrado por hora de atendimento, em reais. |
| status        | VARCHAR(10)  | NN, DEFAULT 'ATIVO', CHECK (ATIVO, INATIVO) | Situação cadastral; inativação lógica.           |

Fonte: elaborado pelos autores (2026). Profissionais que prestam o serviço.

### 5.2 ALUNO

**Quadro 6 – Dicionário de dados da tabela ALUNO**

| **Atributo**    | **Tipo**     | **Restrições**                              | **Descrição**                                          |
|-----------------|--------------|---------------------------------------------|--------------------------------------------------------|
| id_aluno        | INT          | PK, NN, AI                                  | Identificador único do aluno.                          |
| nome            | VARCHAR(100) | NN                                          | Nome completo do aluno.                                |
| cpf             | CHAR(11)     | UQ, NN, CHECK (11 dígitos numéricos)        | CPF, somente dígitos.                                  |
| email           | VARCHAR(100) | UQ, NN                                      | E-mail de contato.                                     |
| telefone        | VARCHAR(15)  | NN                                          | Telefone de contato.                                   |
| data_nascimento | DATE         | NN                                          | Data de nascimento; a idade é calculada nas consultas. |
| sexo            | CHAR(1)      | NN, CHECK (M, F, O)                         | Sexo informado: M, F ou O.                             |
| data_cadastro   | DATE         | NN, DEFAULT (CURRENT_DATE)                  | Data em que o aluno foi cadastrado.                    |
| status          | VARCHAR(10)  | NN, DEFAULT 'ATIVO', CHECK (ATIVO, INATIVO) | Situação cadastral; inativação lógica.                 |

Fonte: elaborado pelos autores (2026). Clientes atendidos.

### 5.3 PERFIL_ALUNO

**Quadro 7 – Dicionário de dados da tabela PERFIL_ALUNO**

| **Atributo**                | **Tipo**     | **Restrições**                                                                                  | **Descrição**                                                      |
|-----------------------------|--------------|-------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| id_aluno                    | INT          | PK, FK, NN → ALUNO                                                                              | Identifica o aluno dono do perfil; é chave primária e estrangeira. |
| objetivo                    | VARCHAR(40)  | NN, CHECK (EMAGRECIMENTO, HIPERTROFIA, CONDICIONAMENTO, REABILITACAO, QUALIDADE_DE_VIDA, FORCA) | Objetivo físico principal.                                         |
| nivel_experiencia           | VARCHAR(15)  | NN, CHECK (INICIANTE, INTERMEDIARIO, AVANCADO)                                                  | Nível de experiência com treino.                                   |
| restricoes_medicas          | VARCHAR(255) | Opcional                                                                                        | Restrições médicas relevantes para o treino.                       |
| contato_emergencia          | VARCHAR(100) | NN                                                                                              | Nome do contato de emergência.                                     |
| telefone_emergencia         | VARCHAR(15)  | NN                                                                                              | Telefone do contato de emergência.                                 |
| frequencia_semanal_desejada | TINYINT      | NN, DEFAULT 3, CHECK (1 a 7)                                                                    | Número de dias de treino por semana desejado pelo aluno.           |

Fonte: elaborado pelos autores (2026). Dados complementares do aluno (1:1 com ALUNO).

### 5.4 GRUPO_MUSCULAR

**Quadro 8 – Dicionário de dados da tabela GRUPO_MUSCULAR**

| **Atributo** | **Tipo**     | **Restrições** | **Descrição**                          |
|--------------|--------------|----------------|----------------------------------------|
| id_grupo     | INT          | PK, NN, AI     | Identificador único do grupo muscular. |
| nome         | VARCHAR(40)  | UQ, NN         | Nome do grupo muscular.                |
| descricao    | VARCHAR(150) | Opcional       | Descrição do grupo.                    |

Fonte: elaborado pelos autores (2026). Classificação dos exercícios.

### 5.5 EXERCICIO

**Quadro 9 – Dicionário de dados da tabela EXERCICIO**

| **Atributo**      | **Tipo**     | **Restrições**                                 | **Descrição**                          |
|-------------------|--------------|------------------------------------------------|----------------------------------------|
| id_exercicio      | INT          | PK, NN, AI                                     | Identificador único do exercício.      |
| id_grupo          | INT          | FK, NN → GRUPO_MUSCULAR                        | Grupo muscular principal do exercício. |
| nome              | VARCHAR(80)  | UQ, NN                                         | Nome do exercício.                     |
| equipamento       | VARCHAR(50)  | NN                                             | Equipamento utilizado.                 |
| nivel_dificuldade | VARCHAR(15)  | NN, CHECK (INICIANTE, INTERMEDIARIO, AVANCADO) | Nível de dificuldade.                  |
| descricao         | VARCHAR(255) | Opcional                                       | Descrição ou orientação de execução.   |

Fonte: elaborado pelos autores (2026). Catálogo de exercícios.

### 5.6 PLANO_TREINO

**Quadro 10 – Dicionário de dados da tabela PLANO_TREINO**

| **Atributo** | **Tipo**     | **Restrições**                                           | **Descrição**                   |
|--------------|--------------|----------------------------------------------------------|---------------------------------|
| id_plano     | INT          | PK, NN, AI                                               | Identificador único do plano.   |
| id_aluno     | INT          | FK, NN → ALUNO                                           | Aluno a quem o plano pertence.  |
| id_personal  | INT          | FK, NN → PERSONAL_TRAINER                                | Personal que elaborou o plano.  |
| nome         | VARCHAR(80)  | NN                                                       | Nome do plano.                  |
| descricao    | VARCHAR(255) | Opcional                                                 | Descrição do plano.             |
| data_inicio  | DATE         | NN                                                       | Data de início de vigência.     |
| data_fim     | DATE         | Opcional, CHECK (nulo ou \>= data_inicio)                | Data de término, quando houver. |
| status       | VARCHAR(10)  | NN, DEFAULT 'ATIVO', CHECK (ATIVO, CONCLUIDO, CANCELADO) | Situação do plano.              |

Fonte: elaborado pelos autores (2026). Planos de treinamento personalizados.

### 5.7 ITEM_PLANO

**Quadro 11 – Dicionário de dados da tabela ITEM_PLANO**

| **Atributo**      | **Tipo**     | **Restrições**                                                           | **Descrição**                                   |
|-------------------|--------------|--------------------------------------------------------------------------|-------------------------------------------------|
| id_item_plano     | INT          | PK, NN, AI                                                               | Identificador único do item (chave substituta). |
| id_plano          | INT          | FK, NN → PLANO_TREINO; UQ (id_plano, ordem); UQ (id_plano, id_exercicio) | Plano ao qual o item pertence.                  |
| id_exercicio      | INT          | FK, NN → EXERCICIO                                                       | Exercício prescrito.                            |
| ordem             | TINYINT      | NN, CHECK (\> 0)                                                         | Posição do exercício no plano; única por plano. |
| series            | TINYINT      | NN, CHECK (\> 0)                                                         | Número de séries.                               |
| repeticoes        | TINYINT      | NN, CHECK (\> 0)                                                         | Número de repetições por série.                 |
| carga_sugerida_kg | DECIMAL(5,1) | Opcional, CHECK (nulo ou \>= 0)                                          | Carga sugerida, em quilogramas.                 |
| descanso_segundos | SMALLINT     | NN, DEFAULT 60, CHECK (\>= 0)                                            | Tempo de descanso entre séries, em segundos.    |

Fonte: elaborado pelos autores (2026). Associativa PLANO_TREINO × EXERCICIO (N:N).

### 5.8 AULA

**Quadro 12 – Dicionário de dados da tabela AULA**

| **Atributo** | **Tipo**     | **Restrições**                                                         | **Descrição**                 |
|--------------|--------------|------------------------------------------------------------------------|-------------------------------|
| id_aula      | INT          | PK, NN, AI                                                             | Identificador único da aula.  |
| id_aluno     | INT          | FK, NN → ALUNO                                                         | Aluno atendido.               |
| id_personal  | INT          | FK, NN → PERSONAL_TRAINER                                              | Personal que ministra a aula. |
| data_aula    | DATE         | NN                                                                     | Data da aula.                 |
| hora_inicio  | TIME         | NN                                                                     | Horário de início.            |
| hora_fim     | TIME         | NN, CHECK (\> hora_inicio)                                             | Horário de término.           |
| local        | VARCHAR(60)  | NN                                                                     | Local de realização.          |
| tipo_aula    | VARCHAR(30)  | NN                                                                     | Modalidade da aula.           |
| status       | VARCHAR(10)  | NN, DEFAULT 'AGENDADA', CHECK (AGENDADA, REALIZADA, CANCELADA, FALTOU) | Situação da aula.             |
| observacoes  | VARCHAR(255) | Opcional                                                               | Observações livres.           |

Fonte: elaborado pelos autores (2026). Agendamento e controle das aulas.

### 5.9 AVALIACAO_FISICA

**Quadro 13 – Dicionário de dados da tabela AVALIACAO_FISICA**

| **Atributo**       | **Tipo**     | **Restrições**                         | **Descrição**                              |
|--------------------|--------------|----------------------------------------|--------------------------------------------|
| id_avaliacao       | INT          | PK, NN, AI                             | Identificador único da avaliação.          |
| id_aluno           | INT          | FK, NN → ALUNO                         | Aluno avaliado.                            |
| id_personal        | INT          | FK, NN → PERSONAL_TRAINER              | Personal responsável pela avaliação.       |
| data_avaliacao     | DATE         | NN                                     | Data da avaliação.                         |
| peso_kg            | DECIMAL(5,2) | NN, CHECK (\> 0)                       | Peso, em quilogramas.                      |
| altura_m           | DECIMAL(3,2) | NN, CHECK (\> 0)                       | Altura, em metros.                         |
| percentual_gordura | DECIMAL(4,1) | Opcional, CHECK (nulo ou entre 3 e 60) | Percentual de gordura corporal.            |
| cintura_cm         | DECIMAL(5,1) | Opcional, CHECK (nulo ou \> 0)         | Circunferência da cintura, em centímetros. |
| observacoes        | VARCHAR(255) | Opcional                               | Observações livres.                        |

Fonte: elaborado pelos autores (2026). Avaliações físicas periódicas.

### 5.10 PAGAMENTO

**Quadro 14 – Dicionário de dados da tabela PAGAMENTO**

| **Atributo**    | **Tipo**     | **Restrições**                                                                | **Descrição**                          |
|-----------------|--------------|-------------------------------------------------------------------------------|----------------------------------------|
| id_pagamento    | INT          | PK, NN, AI                                                                    | Identificador único do pagamento.      |
| id_aluno        | INT          | FK, NN → ALUNO; UQ (id_aluno, referencia_mes)                                 | Aluno responsável pela mensalidade.    |
| referencia_mes  | CHAR(7)      | NN, CHECK (formato AAAA-MM)                                                   | Mês de referência da mensalidade.      |
| valor           | DECIMAL(8,2) | NN, CHECK (\> 0)                                                              | Valor da mensalidade, em reais.        |
| data_vencimento | DATE         | NN                                                                            | Data de vencimento.                    |
| data_pagamento  | DATE         | Opcional; obrigatória se status = PAGO                                        | Data em que a mensalidade foi quitada. |
| forma_pagamento | VARCHAR(20)  | Opcional, CHECK (PIX, CARTAO_CREDITO, CARTAO_DEBITO, DINHEIRO, TRANSFERENCIA) | Forma de pagamento utilizada.          |
| status          | VARCHAR(10)  | NN, DEFAULT 'PENDENTE', CHECK (PENDENTE, PAGO, ATRASADO)                      | Situação da mensalidade.               |

Fonte: elaborado pelos autores (2026). Controle financeiro das mensalidades.

### 5.11 REGISTRO_TREINO

**Quadro 15 – Dicionário de dados da tabela REGISTRO_TREINO**

| **Atributo**          | **Tipo**     | **Restrições**               | **Descrição**                    |
|-----------------------|--------------|------------------------------|----------------------------------|
| id_registro           | INT          | PK, NN, AI                   | Identificador único do registro. |
| id_aluno              | INT          | FK, NN → ALUNO               | Aluno que executou o exercício.  |
| id_exercicio          | INT          | FK, NN → EXERCICIO           | Exercício executado.             |
| data_execucao         | DATE         | NN                           | Data da execução.                |
| series_realizadas     | TINYINT      | NN, CHECK (\> 0)             | Número de séries realizadas.     |
| repeticoes_realizadas | SMALLINT     | NN, CHECK (\> 0)             | Média de repetições por série.   |
| carga_kg              | DECIMAL(5,1) | NN, DEFAULT 0, CHECK (\>= 0) | Carga utilizada, em quilogramas. |
| observacoes           | VARCHAR(255) | Opcional                     | Observações livres.              |

Fonte: elaborado pelos autores (2026). Histórico de execução de exercícios (N:N ALUNO × EXERCICIO).

## 6. Justificativa da normalização

O esquema foi projetado para atingir a Terceira Forma Normal. Esta seção expõe como cada forma normal é alcançada e apresenta exemplos de decomposição, com tabelas hipotéticas que ilustram o problema que a modelagem evitou.

### 6.1 Primeira Forma Normal (1FN)

Todos os atributos do esquema são atômicos, sem listas nem grupos repetidos. Os atributos compostos foram desdobrados em colunas próprias: o contato de emergência é dividido em nome e telefone, o horário da aula em hora de início e hora de fim, e a referência de cada mensalidade é um único valor no formato AAAA-MM. Os exercícios de um plano não são guardados em uma coluna multivalorada, e sim em linhas da tabela ITEM_PLANO, conforme o Exemplo 2 da Seção 6.4.

### 6.2 Segunda Forma Normal (2FN)

A 2FN trata de dependências parciais em chaves compostas. As tabelas associativas adotam chave primária substituta (id_item_plano e id_registro), de modo que não há chave composta na qual um atributo dependa de apenas parte dela. Os atributos de ITEM_PLANO (ordem, séries, repetições, carga sugerida e descanso) dependem do vínculo completo entre plano e exercício, e os dados do exercício ficam em EXERCICIO. A unicidade lógica do par (id_plano, id_exercicio) é preservada por uma restrição UNIQUE.

### 6.3 Terceira Forma Normal (3FN)

Não há dependência transitiva entre atributos não chave. O grupo muscular está fora de EXERCICIO, o IMC não é armazenado em AVALIACAO_FISICA e o personal não está em ALUNO nem em REGISTRO_TREINO. Em cada tabela, os atributos descrevem apenas a entidade identificada pela chave primária.

### 6.4 Exemplos de decomposição

#### 6.4.1 Exemplo 1: grupo muscular em EXERCICIO (3FN)

Suponha que o grupo muscular e sua descrição fossem guardados na própria tabela de exercícios. Haveria dependência transitiva: id_exercicio determina o nome do grupo, e o nome do grupo determina a descrição. As consequências seriam a repetição da descrição em cada exercício do mesmo grupo (anomalia de atualização), a impossibilidade de cadastrar um grupo sem exercício (anomalia de inserção) e a perda da descrição do grupo ao excluir seu último exercício (anomalia de exclusão). O Quadro 16 compara as duas estruturas.

**Quadro 16 – Decomposição do grupo muscular para atingir a 3FN**

```sql
GRUPO_MUSCULAR (id_grupo, nome, descricao)
EXERCICIO (id_exercicio, id_grupo, nome, equipamento, nivel_dificuldade, descricao)
```

Fonte: elaborado pelos autores (2026).

#### 6.4.2 Exemplo 2: exercícios de um plano (1FN e N:N)

Uma tabela de planos com uma coluna “exercícios” contendo vários nomes separados por vírgula violaria a 1FN, por conter valores não atômicos, e não permitiria guardar séries, repetições e carga de cada exercício. A solução é a tabela associativa ITEM_PLANO, em que cada linha representa um exercício em um plano, com seus próprios atributos. O mesmo exercício pode aparecer em vários planos e um plano reúne vários exercícios, o que realiza o relacionamento N:N.

#### 6.4.3 Exemplo 3: atributo do exercício em ITEM_PLANO (2FN)

Se ITEM_PLANO usasse a chave composta (id_plano, id_exercicio) e guardasse o nome do exercício, esse atributo dependeria apenas de id_exercicio, uma dependência parcial que fere a 2FN. A decomposição mantém o nome do exercício em EXERCICIO e deixa em ITEM_PLANO somente os atributos do vínculo.

#### 6.4.4 Exemplo 4: aula em REGISTRO_TREINO (3FN)

Se REGISTRO_TREINO guardasse id_aula e id_aluno ao mesmo tempo, o aluno seria determinado pela aula, o que configura dependência transitiva (id_registro determina id_aula, que determina id_aluno). Por isso a tabela referencia diretamente o aluno e o exercício, e a relação entre execução e aula pode ser obtida, quando necessário, pela combinação de aluno e data.

### 6.5 Atributos derivados

Atributos que podem ser calculados a partir de outros não são armazenados, pois a redundância geraria risco de inconsistência. O IMC é calculado como peso dividido pelo quadrado da altura (Consulta Q12), a idade a partir da data de nascimento, e o total pago por aluno pela soma das mensalidades quitadas (Consulta Q08).

## 7. Catálogo de consultas

Esta seção reúne as quinze consultas do projeto. Para cada uma são apresentados a pergunta de negócio, uma descrição em linguagem natural, o código SQL e um exemplo de saída obtido da execução no MySQL. Quando a saída é longa, a tabela exibe apenas as primeiras linhas, e isso é indicado no título. O Quadro 17 resume o conjunto.

**Quadro 17 – Resumo das consultas do projeto**

| **Cód.** | **Categoria**            | **Pergunta de negócio**                                                      | **Recursos principais**                                                     |
|----------|--------------------------|------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| Q01      | Simples                  | Quais alunos estão ativos?                                                   | SELECT, WHERE, ORDER BY                                                     |
| Q02      | Simples                  | Quais alunos têm nome iniciado por “M” e e-mail do domínio email.com?        | LIKE, AND, ORDER BY                                                         |
| Q03      | Simples                  | Quais mensalidades de outubro/2026 ainda não foram quitadas?                 | BETWEEN, IN, AND, ORDER BY                                                  |
| Q04      | Simples                  | Quais tipos de aula são oferecidos?                                          | DISTINCT, ORDER BY                                                          |
| Q05      | Simples                  | Quais são os 5 personais ativos com maior valor da hora?                     | WHERE, ORDER BY, LIMIT                                                      |
| Q06      | Simples                  | Quais exercícios de nível iniciante ou intermediário usam halteres ou barra? | IN, LIKE, OR, AND, ORDER BY                                                 |
| Q07      | JOIN (2 tabelas)         | Quais exercícios pertencem a cada grupo muscular?                            | INNER JOIN, ORDER BY                                                        |
| Q08      | JOIN (2 tabelas)         | Quanto cada aluno já pagou em mensalidades?                                  | INNER JOIN, COUNT, SUM, GROUP BY, ORDER BY, LIMIT                           |
| Q09      | JOIN (2 tabelas)         | Quais personais realizaram 3 ou mais aulas e qual a duração média?           | INNER JOIN, COUNT, AVG, HAVING, GROUP BY, funções de tempo                  |
| Q10      | JOIN (4 tabelas)         | Qual é o plano de treino completo de uma aluna?                              | INNER JOIN em quatro tabelas, WHERE, ORDER BY                               |
| Q11      | JOIN (3 tabelas)         | Como evolui a carga por grupo muscular?                                      | INNER JOIN em três tabelas, COUNT, AVG, MAX, GROUP BY, HAVING               |
| Q12      | JOIN (4 tabelas)         | Qual o IMC atual e a variação de peso de cada aluno?                         | INNER JOIN em quatro tabelas (uma delas subconsulta), MIN, MAX, CASE, ROUND |
| Q13      | Agregação (1 tabela)     | Qual o faturamento mensal, separando recebido e em aberto?                   | SUM, CASE, COUNT, GROUP BY, ORDER BY                                        |
| Q14      | Bonificação: subconsulta | Quais alunos pagam mensalidade acima da média e já tiveram atraso?           | Subconsulta escalar (AVG), subconsulta com IN, INNER JOIN, MAX, GROUP BY    |
| Q15      | Bonificação: LEFT JOIN   | Quais alunos ativos não têm nenhuma aula agendada?                           | LEFT JOIN, IS NULL, INNER JOIN, ORDER BY                                    |

Fonte: elaborado pelos autores (2026).

As consultas Q01 a Q06 são simples. As consultas Q07 a Q12 usam INNER JOIN com duas, três ou quatro tabelas, além de GROUP BY, HAVING e funções de agregação. A consulta Q13 é uma agregação sobre uma única tabela, para o faturamento mensal. As consultas Q14 e Q15 são de bonificação, com subconsulta e LEFT JOIN.

### 7.1 Consultas simples

#### 7.1.1 Q01 – Quais alunos estão ativos?

**Descrição.** Lista os alunos com status ATIVO, em ordem alfabética, com os dados de contato. **Utilidade.** Mantém a lista de contato atualizada para a agenda do personal. **Recursos.** SELECT, WHERE, ORDER BY.

**Quadro 18 – Código SQL da consulta Q01**

```sql
SELECT id_aluno, nome, email, telefone
FROM ALUNO
WHERE status = 'ATIVO'
ORDER BY nome ASC;
```

Fonte: elaborado pelos autores (2026).

**Tabela 1 – Resultado da consulta Q01 (11 de 17 linhas)**

| **id_aluno** | **nome**                | **email**                 | **telefone**      |
|--------------|-------------------------|---------------------------|-------------------|
| 19           | Aline Gomes Peixoto     | aline.peixoto@email.com   | \(38\) 99326-5951 |
| 1            | Ana Beatriz Fonseca     | ana.fonseca@email.com     | \(38\) 98799-3433 |
| 9            | Beatriz Lacerda Moura   | beatriz.moura@email.com   | \(38\) 98010-2525 |
| 2            | Carlos Eduardo Pinheiro | carlos.pinheiro@email.com | \(38\) 99323-6790 |
| 12           | Gabriel Santana Neves   | gabriel.neves@email.com   | \(38\) 99554-6836 |
| 7            | Isabela Rezende Campos  | isabela.campos@email.com  | \(38\) 98624-4067 |
| 4            | João Pedro Guimarães    | joao.guimaraes@email.com  | \(38\) 98688-8517 |
| 16           | Leonardo Cordeiro Paiva | leonardo.paiva@email.com  | \(38\) 99763-9212 |
| 5            | Letícia Azevedo Prado   | leticia.prado@email.com   | \(38\) 99327-9925 |
| 6            | Marcos Vinícius Teles   | marcos.teles@email.com    | \(38\) 99832-3256 |
| 3            | Mariana Castro Vieira   | mariana.vieira@email.com  | \(38\) 99019-8644 |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** A consulta retorna 17 alunos ativos; a tabela mostra os onze primeiros em ordem alfabética.

#### 7.1.2 Q02 – Quais alunos têm nome iniciado por “M” e e-mail do domínio email.com?

**Descrição.** Busca no cadastro os alunos cujo nome começa com a letra M e cujo e-mail pertence ao domínio email.com. **Utilidade.** Facilita localizar um aluno quando só se lembra de parte do nome. **Recursos.** LIKE, AND, ORDER BY.

**Quadro 19 – Código SQL da consulta Q02**

```sql
SELECT id_aluno, nome, email
FROM ALUNO
WHERE nome LIKE 'M%' AND email LIKE '%@email.com'
ORDER BY nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 2 – Resultado da consulta Q02**

| **id_aluno** | **nome**               | **email**                |
|--------------|------------------------|--------------------------|
| 6            | Marcos Vinícius Teles  | marcos.teles@email.com   |
| 3            | Mariana Castro Vieira  | mariana.vieira@email.com |
| 14           | Matheus Oliveira Brito | matheus.brito@email.com  |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Três alunos atendem simultaneamente aos dois critérios de busca.

#### 7.1.3 Q03 – Quais mensalidades de outubro/2026 ainda não foram quitadas?

**Descrição.** Lista as mensalidades com vencimento em outubro de 2026 cujo status é PENDENTE ou ATRASADO. **Utilidade.** Identifica a inadimplência de um mês específico para cobrança. **Recursos.** BETWEEN, IN, AND, ORDER BY.

**Quadro 20 – Código SQL da consulta Q03**

```sql
SELECT id_pagamento, id_aluno, referencia_mes, valor, data_vencimento, status
FROM PAGAMENTO
WHERE data_vencimento BETWEEN '2026-10-01' AND '2026-10-31'
AND status IN ('PENDENTE', 'ATRASADO')
ORDER BY data_vencimento, id_aluno;
```

Fonte: elaborado pelos autores (2026).

**Tabela 3 – Resultado da consulta Q03**

| **id_pagamento** | **id_aluno** | **referencia_mes** | **valor** | **data_vencimento** | **status** |
|------------------|--------------|--------------------|-----------|---------------------|------------|
| 3                | 1            | 2026-10            | 300.00    | 2026-10-10          | ATRASADO   |
| 15               | 4            | 2026-10            | 450.00    | 2026-10-10          | ATRASADO   |
| 19               | 5            | 2026-10            | 250.00    | 2026-10-10          | ATRASADO   |
| 23               | 6            | 2026-10            | 300.00    | 2026-10-10          | ATRASADO   |
| 35               | 9            | 2026-10            | 450.00    | 2026-10-10          | ATRASADO   |
| 39               | 10           | 2026-10            | 250.00    | 2026-10-10          | ATRASADO   |
| 59               | 15           | 2026-10            | 250.00    | 2026-10-10          | ATRASADO   |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Sete mensalidades, todas atrasadas e com vencimento em 10/10/2026, somam R\$ 2.250,00, valor que coincide com o montante em aberto de outubro na Consulta Q13.

#### 7.1.4 Q04 – Quais tipos de aula são oferecidos?

**Descrição.** Mostra cada modalidade de aula uma única vez, sem repetições. **Utilidade.** Apresenta o portfólio de modalidades já praticadas. **Recursos.** DISTINCT, ORDER BY.

**Quadro 21 – Código SQL da consulta Q04**

```sql
SELECT DISTINCT tipo_aula
FROM AULA
ORDER BY tipo_aula;
```

Fonte: elaborado pelos autores (2026).

**Tabela 4 – Resultado da consulta Q04**

| **tipo_aula**      |
|--------------------|
| Aula experimental  |
| Avaliação e treino |
| Corrida orientada  |
| Funcional          |
| Mobilidade         |
| Musculação         |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Foram registradas seis modalidades distintas de aula.

#### 7.1.5 Q05 – Quais são os 5 personais ativos com maior valor da hora?

**Descrição.** Apresenta o ranking dos cinco maiores valores de hora entre os profissionais ativos. **Utilidade.** Apoia a análise dos preços praticados pela equipe. **Recursos.** WHERE, ORDER BY, LIMIT.

**Quadro 22 – Código SQL da consulta Q05**

```sql
SELECT id_personal, nome, especialidade, valor_hora
FROM PERSONAL_TRAINER
WHERE status = 'ATIVO'
ORDER BY valor_hora DESC
LIMIT 5;
```

Fonte: elaborado pelos autores (2026).

**Tabela 5 – Resultado da consulta Q05**

| **id_personal** | **nome**                | **especialidade**                     | **valor_hora** |
|-----------------|-------------------------|---------------------------------------|----------------|
| 14              | Renata Cavalcanti Pinto | Reabilitação e fisioterapia esportiva | 180.00         |
| 4               | Fernanda Oliveira Costa | Reabilitação e fisioterapia esportiva | 170.00         |
| 13              | Felipe Araújo Batista   | Força e powerlifting                  | 160.00         |
| 5               | Thiago Ribeiro Santos   | Força e powerlifting                  | 150.00         |
| 1               | Rafael Moreira Lima     | Musculação e hipertrofia              | 140.00         |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** O maior valor de hora é de R\$ 180,00, cobrado por uma profissional de reabilitação.

#### 7.1.6 Q06 – Quais exercícios de nível iniciante ou intermediário usam halteres ou barra?

**Descrição.** Filtra o catálogo por nível de dificuldade (iniciante ou intermediário) e por tipo de equipamento (halteres ou barra). **Utilidade.** Ajuda a montar planos para alunos com pouca experiência. **Recursos.** IN, LIKE, OR, AND, ORDER BY.

**Quadro 23 – Código SQL da consulta Q06**

```sql
SELECT id_exercicio, nome, equipamento, nivel_dificuldade
FROM EXERCICIO
WHERE nivel_dificuldade IN ('INICIANTE', 'INTERMEDIARIO')
AND (equipamento LIKE '%Halter%' OR equipamento LIKE 'Barra%')
ORDER BY nivel_dificuldade, nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 6 – Resultado da consulta Q06 (10 de 14 linhas)**

| **id_exercicio** | **nome**                     | **equipamento**  | **nivel_dificuldade** |
|------------------|------------------------------|------------------|-----------------------|
| 2                | Crucifixo com Halteres       | Halteres e banco | INICIANTE             |
| 6                | Elevação Lateral             | Halteres         | INICIANTE             |
| 25               | Encolhimento com Halteres    | Halteres         | INICIANTE             |
| 11               | Rosca de Punho               | Barra            | INICIANTE             |
| 7                | Rosca Direta com Barra W     | Barra W          | INICIANTE             |
| 8                | Rosca Martelo                | Halteres         | INICIANTE             |
| 28               | Agachamento Sumô             | Halter           | INTERMEDIARIO         |
| 5                | Desenvolvimento com Halteres | Halteres         | INTERMEDIARIO         |
| 19               | Elevação Pélvica             | Barra e banco    | INTERMEDIARIO         |
| 26               | Remada Alta                  | Barra            | INTERMEDIARIO         |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** A consulta retorna 14 exercícios; a tabela mostra os dez primeiros, ordenados por nível e nome.

### 7.2 Consultas com junção e agregação

#### 7.2.1 Q07 – Quais exercícios pertencem a cada grupo muscular?

**Descrição.** Cruza o catálogo de exercícios com a classificação por grupo muscular. **Utilidade.** Mostra a organização do catálogo para a montagem dos planos. **Recursos.** INNER JOIN, ORDER BY.

**Quadro 24 – Código SQL da consulta Q07**

```sql
SELECT g.nome AS grupo_muscular, e.nome AS exercicio, e.equipamento
FROM EXERCICIO e
INNER JOIN GRUPO_MUSCULAR g ON g.id_grupo = e.id_grupo
ORDER BY g.nome, e.nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 7 – Resultado da consulta Q07 (9 de 30 linhas)**

| **grupo_muscular** | **exercicio**            | **equipamento** |
|--------------------|--------------------------|-----------------|
| Abdômen            | Abdominal Supra          | Solo            |
| Abdômen            | Prancha Isométrica       | Solo            |
| Adutores           | Agachamento Sumô         | Halter          |
| Adutores           | Cadeira Adutora          | Cadeira adutora |
| Antebraço          | Rosca de Punho           | Barra           |
| Antebraço          | Rosca Inversa            | Barra W         |
| Bíceps             | Rosca Direta com Barra W | Barra W         |
| Bíceps             | Rosca Martelo            | Halteres        |
| Corpo Inteiro      | Burpee                   | Peso corporal   |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** A junção retorna 30 linhas, uma para cada exercício do catálogo, o que confirma que todo exercício pertence a um grupo muscular (regra RN07).

#### 7.2.2 Q08 – Quanto cada aluno já pagou em mensalidades?

**Descrição.** Soma apenas os pagamentos quitados de cada aluno e ordena do maior para o menor total, exibindo os dez primeiros. **Utilidade.** Mede a receita acumulada por aluno. **Recursos.** INNER JOIN, COUNT, SUM, GROUP BY, ORDER BY, LIMIT.

**Quadro 25 – Código SQL da consulta Q08**

```sql
SELECT a.id_aluno, a.nome,
COUNT(p.id_pagamento) AS parcelas_pagas,
SUM(p.valor) AS total_pago
FROM ALUNO a
INNER JOIN PAGAMENTO p ON p.id_aluno = a.id_aluno
WHERE p.status = 'PAGO'
GROUP BY a.id_aluno, a.nome
ORDER BY total_pago DESC, a.nome
LIMIT 10;
```

Fonte: elaborado pelos autores (2026).

**Tabela 8 – Resultado da consulta Q08**

| **id_aluno** | **nome**                 | **parcelas_pagas** | **total_pago** |
|--------------|--------------------------|--------------------|----------------|
| 2            | Carlos Eduardo Pinheiro  | 4                  | 1400.00        |
| 12           | Gabriel Santana Neves    | 4                  | 1400.00        |
| 7            | Isabela Rezende Campos   | 4                  | 1400.00        |
| 17           | Natália Siqueira Lemos   | 4                  | 1400.00        |
| 19           | Aline Gomes Peixoto      | 3                  | 1350.00        |
| 14           | Matheus Oliveira Brito   | 3                  | 1350.00        |
| 13           | Helena Machado Ventura   | 3                  | 1200.00        |
| 3            | Mariana Castro Vieira    | 3                  | 1200.00        |
| 18           | Ricardo Tavares Duarte   | 3                  | 1200.00        |
| 8            | Rodrigo Nascimento Braga | 3                  | 1200.00        |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Quatro alunos pagaram as quatro parcelas e acumulam R\$ 1.400,00 cada um; a tabela apresenta os dez maiores totais.

#### 7.2.3 Q09 – Quais personais realizaram 3 ou mais aulas e qual a duração média?

**Descrição.** Conta as aulas com status REALIZADA de cada personal, calcula a duração média em horas e mantém apenas os profissionais com três ou mais aulas. **Utilidade.** Avalia a carga de trabalho efetiva de cada profissional. **Recursos.** INNER JOIN, COUNT, AVG, HAVING, GROUP BY, funções de tempo.

**Quadro 26 – Código SQL da consulta Q09**

```sql
SELECT pt.nome AS personal,
COUNT(au.id_aula) AS aulas_realizadas,
ROUND(AVG(TIME_TO_SEC(TIMEDIFF(au.hora_fim,
au.hora_inicio)) / 3600), 1) AS duracao_media_h
FROM PERSONAL_TRAINER pt
INNER JOIN AULA au ON au.id_personal = pt.id_personal
WHERE au.status = 'REALIZADA'
GROUP BY pt.id_personal, pt.nome
HAVING COUNT(au.id_aula) >= 3
ORDER BY aulas_realizadas DESC, pt.nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 9 – Resultado da consulta Q09**

| **personal**           | **aulas_realizadas** | **duracao_media_h** |
|------------------------|----------------------|---------------------|
| Camila Duarte Souza    | 5                    | 1.0                 |
| Rafael Moreira Lima    | 5                    | 1.0                 |
| Juliana Pereira Rocha  | 4                    | 1.0                 |
| Patrícia Nogueira Dias | 3                    | 1.0                 |
| Thiago Ribeiro Santos  | 3                    | 1.0                 |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Cinco profissionais têm três ou mais aulas realizadas, todas com duração média de uma hora.

#### 7.2.4 Q10 – Qual é o plano de treino completo de uma aluna?

**Descrição.** Une aluno, plano, itens do plano e exercícios, exibindo o treino de uma aluna na ordem de execução. **Utilidade.** Gera a ficha de treino que o personal entrega ao aluno. **Recursos.** INNER JOIN em quatro tabelas, WHERE, ORDER BY.

**Quadro 27 – Código SQL da consulta Q10**

```sql
SELECT a.nome AS aluno, pl.nome AS plano, i.ordem,
e.nome AS exercicio, i.series, i.repeticoes,
i.descanso_segundos
FROM ALUNO a
INNER JOIN PLANO_TREINO pl ON pl.id_aluno = a.id_aluno
INNER JOIN ITEM_PLANO i ON i.id_plano = pl.id_plano
INNER JOIN EXERCICIO e ON e.id_exercicio = i.id_exercicio
WHERE a.nome = 'Ana Beatriz Fonseca' AND pl.status = 'ATIVO'
ORDER BY pl.id_plano, i.ordem;
```

Fonte: elaborado pelos autores (2026).

**Tabela 10 – Resultado da consulta Q10**

| **aluno**           | **plano**                 | **ordem** | **exercicio**          | **series** | **repeticoes** | **descanso_segundos** |
|---------------------|---------------------------|-----------|------------------------|------------|----------------|-----------------------|
| Ana Beatriz Fonseca | Queima Calórica - Ana     | 1         | Leg Press 45 graus     | 4          | 10             | 90                    |
| Ana Beatriz Fonseca | Queima Calórica - Ana     | 2         | Crucifixo com Halteres | 4          | 12             | 60                    |
| Ana Beatriz Fonseca | Queima Calórica - Ana     | 3         | Rosca Martelo          | 4          | 12             | 60                    |
| Ana Beatriz Fonseca | Queima Calórica - Ana     | 4         | Panturrilha Sentado    | 3          | 12             | 90                    |
| Ana Beatriz Fonseca | Plano de Manutenção - Ana | 1         | Agachamento Livre      | 4          | 15             | 60                    |
| Ana Beatriz Fonseca | Plano de Manutenção - Ana | 2         | Rosca Inversa          | 3          | 8              | 45                    |
| Ana Beatriz Fonseca | Plano de Manutenção - Ana | 3         | Stiff com Barra        | 3          | 15             | 45                    |
| Ana Beatriz Fonseca | Plano de Manutenção - Ana | 4         | Cadeira Adutora        | 3          | 15             | 90                    |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** A aluna possui dois planos ativos, de quatro exercícios cada, exibidos na ordem de execução definida em ITEM_PLANO.

#### 7.2.5 Q11 – Como evolui a carga por grupo muscular?

**Descrição.** Agrega os registros de treino por grupo muscular e mantém os grupos com quatro ou mais execuções, mostrando a carga média e a máxima. **Utilidade.** Acompanha a progressão de carga dos alunos por região do corpo. **Recursos.** INNER JOIN em três tabelas, COUNT, AVG, MAX, GROUP BY, HAVING.

**Quadro 28 – Código SQL da consulta Q11**

```sql
SELECT g.nome AS grupo_muscular,
COUNT(*) AS execucoes,
ROUND(AVG(r.carga_kg), 1) AS carga_media_kg,
MAX(r.carga_kg) AS carga_maxima_kg
FROM REGISTRO_TREINO r
INNER JOIN EXERCICIO e ON e.id_exercicio = r.id_exercicio
INNER JOIN GRUPO_MUSCULAR g ON g.id_grupo = e.id_grupo
GROUP BY g.id_grupo, g.nome
HAVING COUNT(*) >= 4
ORDER BY carga_media_kg DESC;
```

Fonte: elaborado pelos autores (2026).

**Tabela 11 – Resultado da consulta Q11**

| **grupo_muscular** | **execucoes** | **carga_media_kg** | **carga_maxima_kg** |
|--------------------|---------------|--------------------|---------------------|
| Glúteos            | 4             | 36.3               | 42.5                |
| Costas             | 4             | 26.3               | 32.5                |
| Quadríceps         | 6             | 24.6               | 42.5                |
| Adutores           | 8             | 22.5               | 42.5                |
| Trapézio           | 8             | 21.3               | 42.5                |
| Bíceps             | 4             | 21.3               | 32.5                |
| Lombar             | 6             | 19.6               | 32.5                |
| Corpo Inteiro      | 4             | 18.8               | 22.5                |
| Posterior de Coxa  | 6             | 17.9               | 22.5                |
| Antebraço          | 6             | 16.3               | 22.5                |
| Ombros             | 6             | 12.9               | 17.5                |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Onze grupos têm ao menos quatro execuções; Glúteos apresenta a maior carga média (36,3 kg) e Ombros, a menor (12,9 kg).

#### 7.2.6 Q12 – Qual o IMC atual e a variação de peso de cada aluno?

**Descrição.** Compara a primeira e a última avaliação física de cada aluno, calcula a variação de peso e o IMC atual. O IMC é calculado na própria consulta, pois não é armazenado (3FN). Exibe as oito maiores reduções de peso. **Utilidade.** Mede a evolução física frente ao objetivo do aluno. **Recursos.** INNER JOIN em quatro tabelas (uma delas subconsulta), MIN, MAX, CASE, ROUND.

**Quadro 29 – Código SQL da consulta Q12**

```sql
SELECT a.nome AS aluno, pf.objetivo,
ROUND(MAX(CASE WHEN av.data_avaliacao = f.ultima
THEN av.peso_kg END), 1) AS peso_atual_kg,
ROUND(MAX(CASE WHEN av.data_avaliacao = f.primeira
THEN av.peso_kg END), 1) AS peso_inicial_kg,
ROUND(MAX(CASE WHEN av.data_avaliacao = f.ultima
THEN av.peso_kg END)
- MAX(CASE WHEN av.data_avaliacao = f.primeira
THEN av.peso_kg END), 1) AS variacao_kg,
ROUND(MAX(CASE WHEN av.data_avaliacao = f.ultima
THEN av.peso_kg / (av.altura_m * av.altura_m)
END), 1) AS imc_atual
FROM ALUNO a
INNER JOIN PERFIL_ALUNO pf ON pf.id_aluno = a.id_aluno
INNER JOIN AVALIACAO_FISICA av ON av.id_aluno = a.id_aluno
INNER JOIN (SELECT id_aluno,
MIN(data_avaliacao) AS primeira,
MAX(data_avaliacao) AS ultima
FROM AVALIACAO_FISICA
GROUP BY id_aluno) f ON f.id_aluno = a.id_aluno
GROUP BY a.id_aluno, a.nome, pf.objetivo
ORDER BY variacao_kg, a.nome
LIMIT 8;
```

Fonte: elaborado pelos autores (2026).

**Tabela 12 – Resultado da consulta Q12**

| **aluno**              | **objetivo**      | **peso\_​atual\_​kg** | **peso\_​inicial\_​kg** | **variacao\_​kg** | **imc\_​atual** |
|------------------------|-------------------|---------------------|-----------------------|------------------|----------------|
| Ana Beatriz Fonseca    | EMAGRECIMENTO     | 64.5                | 68.0                  | -3.5             | 23.7           |
| Beatriz Lacerda Moura  | EMAGRECIMENTO     | 60.5                | 64.0                  | -3.5             | 24.2           |
| Letícia Azevedo Prado  | EMAGRECIMENTO     | 66.5                | 70.0                  | -3.5             | 25.3           |
| Natália Siqueira Lemos | EMAGRECIMENTO     | 74.5                | 78.0                  | -3.5             | 26.7           |
| Aline Gomes Peixoto    | CONDICIONAMENTO   | 62.2                | 63.0                  | -0.8             | 21.8           |
| Helena Machado Ventura | QUALIDADE_DE_VIDA | 65.2                | 66.0                  | -0.8             | 25.5           |
| Isabela Rezende Campos | CONDICIONAMENTO   | 57.2                | 58.0                  | -0.8             | 20.3           |
| João Pedro Guimarães   | REABILITACAO      | 80.2                | 81.0                  | -0.8             | 24.2           |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** As quatro maiores reduções, de 3,5 kg, ocorrem entre alunos com objetivo de emagrecimento, o que está coerente com o objetivo declarado no perfil.

### 7.3 Consulta de agregação mensal

#### 7.3.1 Q13 – Qual o faturamento mensal, separando recebido e em aberto?

**Descrição.** Consolida, mês a mês, o número de mensalidades, o valor recebido, o valor ainda em aberto e o total previsto. **Utilidade.** Dá visão da saúde financeira do negócio. **Recursos.** SUM, CASE, COUNT, GROUP BY, ORDER BY.

**Quadro 30 – Código SQL da consulta Q13**

```sql
SELECT p.referencia_mes,
COUNT(*) AS mensalidades,
SUM(CASE WHEN p.status = 'PAGO' THEN p.valor ELSE 0 END) AS recebido,
SUM(CASE WHEN p.status <> 'PAGO' THEN p.valor ELSE 0 END) AS em_aberto,
SUM(p.valor) AS total_previsto
FROM PAGAMENTO p
GROUP BY p.referencia_mes
ORDER BY p.referencia_mes;
```

Fonte: elaborado pelos autores (2026).

**Tabela 13 – Resultado da consulta Q13**

| **referencia_mes** | **mensalidades** | **recebido** | **em_aberto** | **total_previsto** |
|--------------------|------------------|--------------|---------------|--------------------|
| 2026-08            | 20               | 7000.00      | 0.00          | 7000.00            |
| 2026-09            | 20               | 7000.00      | 0.00          | 7000.00            |
| 2026-10            | 20               | 4750.00      | 2250.00       | 7000.00            |
| 2026-11            | 20               | 2400.00      | 4600.00       | 7000.00            |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Agosto e setembro estão integralmente quitados; outubro tem R\$ 2.250,00 em aberto e novembro, R\$ 4.600,00, sobre um total previsto de R\$ 7.000,00 por mês.

### 7.4 Consultas de aprofundamento: subconsulta e junção externa

#### 7.4.1 Q14 – Quais alunos pagam mensalidade acima da média e já tiveram atraso?

**Descrição.** Combina uma subconsulta escalar, que calcula a média das mensalidades, com uma subconsulta IN, que lista os alunos com algum pagamento atrasado, e retorna quem atende às duas condições. **Utilidade.** Prioriza a cobrança dos clientes de maior valor. **Recursos.** Subconsulta escalar (AVG), subconsulta com IN, INNER JOIN, MAX, GROUP BY.

**Quadro 31 – Código SQL da consulta Q14**

```sql
SELECT a.id_aluno, a.nome, MAX(p.valor) AS mensalidade
FROM ALUNO a
INNER JOIN PAGAMENTO p ON p.id_aluno = a.id_aluno
WHERE p.valor > (SELECT AVG(valor) FROM PAGAMENTO)
AND a.id_aluno IN (SELECT id_aluno FROM PAGAMENTO
WHERE status = 'ATRASADO')
GROUP BY a.id_aluno, a.nome
ORDER BY mensalidade DESC, a.nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 14 – Resultado da consulta Q14**

| **id_aluno** | **nome**              | **mensalidade** |
|--------------|-----------------------|-----------------|
| 9            | Beatriz Lacerda Moura | 450.00          |
| 4            | João Pedro Guimarães  | 450.00          |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Dois alunos pagam mensalidade de R\$ 450,00, acima da média, e já tiveram atraso, sendo os primeiros a priorizar na cobrança.

#### 7.4.2 Q15 – Quais alunos ativos não têm nenhuma aula agendada?

**Descrição.** Mantém todos os alunos ativos e filtra aqueles para os quais não existe aula com status AGENDADA, exibindo a frequência semanal desejada. **Utilidade.** Lista os alunos que precisam ser contatados para remarcar horários. **Recursos.** LEFT JOIN, IS NULL, INNER JOIN, ORDER BY.

**Quadro 32 – Código SQL da consulta Q15**

```sql
SELECT a.id_aluno, a.nome,
pf.frequencia_semanal_desejada AS freq_desejada
FROM ALUNO a
INNER JOIN PERFIL_ALUNO pf ON pf.id_aluno = a.id_aluno
LEFT JOIN AULA au ON au.id_aluno = a.id_aluno
AND au.status = 'AGENDADA'
WHERE a.status = 'ATIVO' AND au.id_aula IS NULL
ORDER BY a.nome;
```

Fonte: elaborado pelos autores (2026).

**Tabela 15 – Resultado da consulta Q15**

| **id_aluno** | **nome**                | **freq_desejada** |
|--------------|-------------------------|-------------------|
| 19           | Aline Gomes Peixoto     | 4                 |
| 16           | Leonardo Cordeiro Paiva | 5                 |
| 17           | Natália Siqueira Lemos  | 3                 |
| 15           | Sofia Albuquerque Reis  | 4                 |
| 20           | Vitor Hugo Castelo      | 4                 |

Fonte: elaborado pelos autores (2026), a partir da execução no MySQL.

**Análise.** Cinco alunos ativos estão sem aula agendada. O LEFT JOIN com o filtro IS NULL é o que permite listar quem não possui correspondência na tabela AULA.

## 8. Instruções de execução

### 8.1 Pré-requisitos

É necessário ter o MySQL Server na versão 8.0.16 ou superior, pois as restrições CHECK só são aplicadas a partir dela, e o MySQL Workbench, ou o cliente de linha de comando mysql, para executar os scripts. O usuário utilizado deve ter permissão para criar bancos de dados.

### 8.2 Arquivos do repositório

**Quadro 33 – Arquivos SQL do projeto e finalidade**

| **Arquivo**          | **Finalidade**                                                                             |
|----------------------|--------------------------------------------------------------------------------------------|
| 01_criacao_banco.sql | Cria o banco personal_trainer_db e as 11 tabelas, com todas as restrições e índices (DDL). |
| 02_povoamento.sql    | Insere os dados fictícios, com no mínimo 15 registros por tabela (DML).                    |
| 03_consultas.sql     | Reúne as 15 consultas, com comentários explicativos (DQL).                                 |

Fonte: elaborado pelos autores (2026).

### 8.3 Passo a passo no MySQL Workbench

1)  abrir o MySQL Workbench e conectar-se à instância local do MySQL com um usuário com permissão de criação de bancos;

2)  abrir o arquivo 01_criacao_banco.sql pelo menu File \> Open SQL Script;

3)  executar o script inteiro com o atalho Ctrl+Shift+Enter; ao final, a instrução SHOW TABLES deve listar as 11 tabelas;

4)  abrir e executar da mesma forma o arquivo 02_povoamento.sql, que respeita a ordem de dependência do Quadro 38;

5)  abrir o arquivo 03_consultas.sql, selecionar a consulta desejada e executá-la com o atalho Ctrl+Enter, que executa a instrução em que o cursor está posicionado;

6)  conferir o resultado na grade de saída e compará-lo com as tabelas da Seção 7.

### 8.4 Execução por linha de comando

Como alternativa, os mesmos arquivos podem ser executados em sequência pelo cliente mysql, na pasta que contém os scripts:

**Quadro 34 – Comandos para execução dos scripts em linha de comando**

```sql
mysql -u root -p < 01_criacao_banco.sql
mysql -u root -p personal_trainer_db < 02_povoamento.sql
mysql -u root -p personal_trainer_db < 03_consultas.sql
```

Fonte: elaborado pelos autores (2026).

### 8.5 Verificação do povoamento

Para conferir que cada tabela recebeu ao menos quinze registros, pode-se executar a consulta de contagem do Quadro 35.

**Quadro 35 – Consulta de verificação da quantidade de registros por tabela**

```sql
SELECT 'PERSONAL_TRAINER' AS tabela, COUNT(*) AS registros FROM PERSONAL_TRAINER
UNION ALL SELECT 'ALUNO', COUNT(*) FROM ALUNO
UNION ALL SELECT 'PERFIL_ALUNO', COUNT(*) FROM PERFIL_ALUNO
UNION ALL SELECT 'GRUPO_MUSCULAR', COUNT(*) FROM GRUPO_MUSCULAR
UNION ALL SELECT 'EXERCICIO', COUNT(*) FROM EXERCICIO
UNION ALL SELECT 'PLANO_TREINO', COUNT(*) FROM PLANO_TREINO
UNION ALL SELECT 'ITEM_PLANO', COUNT(*) FROM ITEM_PLANO
UNION ALL SELECT 'AULA', COUNT(*) FROM AULA
UNION ALL SELECT 'AVALIACAO_FISICA', COUNT(*) FROM AVALIACAO_FISICA
UNION ALL SELECT 'PAGAMENTO', COUNT(*) FROM PAGAMENTO
UNION ALL SELECT 'REGISTRO_TREINO', COUNT(*) FROM REGISTRO_TREINO;
```

Fonte: elaborado pelos autores (2026).

### 8.6 Problemas comuns

1)  **restrições CHECK sem efeito:** em versões do MySQL anteriores à 8.0.16, a cláusula CHECK é aceita, mas não é aplicada; é preciso atualizar o servidor;

2)  **erro ao executar o script de criação:** o script apaga e recria o banco; se o usuário não tiver permissão de DROP e CREATE, a execução falha;

3)  **erro de chave estrangeira no povoamento:** ocorre quando os arquivos são executados fora de ordem; deve-se seguir a ordem do Quadro 38;

4)  **acentos exibidos incorretamente:** o banco usa utf8mb4; a conexão e o editor também devem usar essa codificação.

## 9. Considerações finais

### 9.1 Dificuldades encontradas

As principais dificuldades foram decidir a granularidade das entidades e conciliar as regras de negócio com a 3FN. Um exemplo foi a tabela REGISTRO_TREINO: a primeira ideia, de associá-la à aula, criaria dependência transitiva entre aula e aluno, e foi descartada em favor da ligação direta com aluno e exercício. Também exigiram cuidado a escolha das políticas de ON DELETE, para preservar o histórico, e a escrita da consulta Q12, que compara a primeira e a última avaliação de cada aluno e combina junções, subconsulta em tabela derivada e expressões CASE. Outra dificuldade foi a dependência de versão do MySQL, já que as restrições CHECK só são aplicadas a partir da versão 8.0.16.

### 9.2 Decisões de projeto

Entre as decisões que mais influenciaram o resultado estão a separação do perfil em tabela própria (1:1), o uso de tabelas associativas com chave substituta para os relacionamentos N:N, a inativação lógica por status, em vez de exclusão física, e o cálculo dos atributos derivados nas consultas. Todas as regras de negócio foram traduzidas em restrições declaradas no próprio banco, de modo que a integridade não depende da aplicação que o utiliza.

### 9.3 Possíveis evoluções

O projeto pode evoluir nos seguintes pontos:

1)  criar visões (views) para as consultas mais usadas, como a ficha de treino e o faturamento mensal;

2)  automatizar a mudança de status das mensalidades para ATRASADO com um evento agendado do MySQL ou um gatilho (trigger);

3)  criar procedimentos armazenados para o cadastro de aluno com perfil e para a geração mensal das mensalidades;

4)  acrescentar uma tabela de usuários e papéis, com privilégios distintos para o personal e para a recepção;

5)  incluir entidades de pacote ou plano comercial e de frequência efetiva às aulas, para comparar a frequência realizada com a desejada;

6)  definir rotinas de cópia de segurança e de restauração do banco.

Conclui-se que o banco atende aos requisitos da disciplina e às regras de negócio levantadas: o esquema está em 3FN, as restrições de integridade são declaradas e testadas, os dados são plausíveis e as quinze consultas respondem a perguntas reais da rotina de um personal trainer.

## 10. Referências bibliográficas

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 10520**: informação e documentação: citações em documentos: apresentação. Rio de Janeiro: ABNT, 2023.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 14724**: informação e documentação: trabalhos acadêmicos: apresentação. 4. ed. Rio de Janeiro: ABNT, 2024.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 6023**: informação e documentação: referências: elaboração. Rio de Janeiro: ABNT, 2018.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 6024**: informação e documentação: numeração progressiva das seções de um documento escrito: apresentação. Rio de Janeiro: ABNT, 2012a.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 6027**: informação e documentação: sumário: apresentação. Rio de Janeiro: ABNT, 2012b.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **NBR 6028**: informação e documentação: resumo, resenha e recensão: apresentação. Rio de Janeiro: ABNT, 2021.

CHEN, Peter Pin-Shan. The entity-relationship model: toward a unified view of data. **ACM Transactions on Database Systems**, New York, v. 1, n. 1, p. 9-36, 1976.

CODD, E. F. A relational model of data for large shared data banks. **Communications of the ACM**, New York, v. 13, n. 6, p. 377-387, 1970.

DATE, C. J. **Introdução a sistemas de bancos de dados**. 8. ed. Rio de Janeiro: Elsevier, 2004.

ELMASRI, Ramez; NAVATHE, Shamkant B. **Sistemas de banco de dados**. 7. ed. São Paulo: Pearson, 2018.

GRAPHVIZ. **Graphviz**: graph visualization software. \[S. l.\], 2026. Disponível em: https://graphviz.org/. Acesso em: 17 nov. 2026.

HEUSER, Carlos Alberto. **Projeto de banco de dados**. 6. ed. Porto Alegre: Bookman, 2009.

INSTITUTO BRASILEIRO DE GEOGRAFIA E ESTATÍSTICA. **Normas de apresentação tabular**. 3. ed. Rio de Janeiro: IBGE, 1993.

ORACLE CORPORATION. **MySQL 8.0 reference manual**. \[S. l.\]: Oracle, 2026a. Disponível em: https://dev.mysql.com/doc/refman/8.0/en/. Acesso em: 17 nov. 2026.

ORACLE CORPORATION. **MySQL Workbench manual**. \[S. l.\]: Oracle, 2026b. Disponível em: https://dev.mysql.com/doc/workbench/en/. Acesso em: 17 nov. 2026.

SILBERSCHATZ, Abraham; KORTH, Henry F.; SUDARSHAN, S. **Sistema de banco de dados**. 6. ed. Rio de Janeiro: Elsevier, 2012.

## Apêndice A – Script de criação do banco de dados

Arquivo `01_criacao_banco.sql`, que cria o banco `personal_trainer_db` com as 11 tabelas, restrições e índices.

```sql
-- PROJETO FINAL DE BANCO DE DADOS
-- Sistema de Gerenciamento de Alunos, Aulas e Exercicios para Personal Trainer
-- Arquivo : 01_criacao_banco.sql (DDL - criacao do banco e das tabelas)
-- SGBD    : MySQL 8.0.16 ou superior (CHECK so e aplicado a partir desta versao)
-- Execucao: MySQL Workbench -> abrir o arquivo -> executar tudo (Ctrl+Shift+Enter)

-- 1. CRIACAO DO BANCO DE DADOS
-- Remove o banco caso ja exista, permitindo reexecutar o script do zero.
-- ATENCAO: apaga todos os dados do banco personal_trainer_db.
DROP DATABASE IF EXISTS personal_trainer_db;

-- utf8mb4 garante suporte completo a acentos e caracteres especiais.
CREATE DATABASE personal_trainer_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE personal_trainer_db;

-- 2. CRIACAO DAS TABELAS
-- Ordem: primeiro as tabelas sem dependencias, depois as que referenciam
-- outras por chave estrangeira.

-- 2.1 PERSONAL_TRAINER - profissionais
CREATE TABLE PERSONAL_TRAINER (
    id_personal   INT          NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(100) NOT NULL,
    cpf           CHAR(11)     NOT NULL,                 -- somente digitos
    email         VARCHAR(100) NOT NULL,
    telefone      VARCHAR(15)  NOT NULL,
    cref          VARCHAR(15)  NOT NULL,                 -- registro no conselho profissional
    especialidade VARCHAR(60)  NULL,
    valor_hora    DECIMAL(8,2) NOT NULL,
    status        VARCHAR(10)  NOT NULL DEFAULT 'ATIVO', -- DEFAULT 1
    CONSTRAINT pk_personal        PRIMARY KEY (id_personal),
    CONSTRAINT uq_personal_cpf    UNIQUE (cpf),
    CONSTRAINT uq_personal_email  UNIQUE (email),
    CONSTRAINT uq_personal_cref   UNIQUE (cref),
    CONSTRAINT ck_personal_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_personal_valor  CHECK (valor_hora > 0),
    CONSTRAINT ck_personal_status CHECK (status IN ('ATIVO', 'INATIVO'))
) ENGINE = InnoDB;

-- 2.2 ALUNO - clientes atendidos
CREATE TABLE ALUNO (
    id_aluno        INT          NOT NULL AUTO_INCREMENT,
    nome            VARCHAR(100) NOT NULL,
    cpf             CHAR(11)     NOT NULL,
    email           VARCHAR(100) NOT NULL,
    telefone        VARCHAR(15)  NOT NULL,
    data_nascimento DATE         NOT NULL,
    sexo            CHAR(1)      NOT NULL,                       -- M, F ou O
    data_cadastro   DATE         NOT NULL DEFAULT (CURRENT_DATE), -- DEFAULT 2
    status          VARCHAR(10)  NOT NULL DEFAULT 'ATIVO',       -- DEFAULT 3
    CONSTRAINT pk_aluno        PRIMARY KEY (id_aluno),
    CONSTRAINT uq_aluno_cpf    UNIQUE (cpf),
    CONSTRAINT uq_aluno_email  UNIQUE (email),
    CONSTRAINT ck_aluno_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_aluno_sexo   CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT ck_aluno_status CHECK (status IN ('ATIVO', 'INATIVO'))
) ENGINE = InnoDB;

-- 2.3 PERFIL_ALUNO - dados complementares do aluno (relacionamento 1:1)
-- A PK e tambem FK para ALUNO: isso garante no maximo um perfil por aluno.
CREATE TABLE PERFIL_ALUNO (
    id_aluno                    INT          NOT NULL,
    objetivo                    VARCHAR(40)  NOT NULL,
    nivel_experiencia           VARCHAR(15)  NOT NULL,
    restricoes_medicas          VARCHAR(255) NULL,
    contato_emergencia          VARCHAR(100) NOT NULL,
    telefone_emergencia         VARCHAR(15)  NOT NULL,
    frequencia_semanal_desejada TINYINT      NOT NULL DEFAULT 3, -- DEFAULT 4
    CONSTRAINT pk_perfil_aluno PRIMARY KEY (id_aluno),
    CONSTRAINT fk_perfil_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_perfil_objetivo CHECK (objetivo IN
        ('EMAGRECIMENTO', 'HIPERTROFIA', 'CONDICIONAMENTO', 'REABILITACAO',
         'QUALIDADE_DE_VIDA', 'FORCA')),
    CONSTRAINT ck_perfil_nivel CHECK (nivel_experiencia IN
        ('INICIANTE', 'INTERMEDIARIO', 'AVANCADO')),
    CONSTRAINT ck_perfil_frequencia CHECK (frequencia_semanal_desejada BETWEEN 1 AND 7)
) ENGINE = InnoDB;

-- 2.4 GRUPO_MUSCULAR - classificacao dos exercicios
CREATE TABLE GRUPO_MUSCULAR (
    id_grupo  INT          NOT NULL AUTO_INCREMENT,
    nome      VARCHAR(40)  NOT NULL,
    descricao VARCHAR(150) NULL,
    CONSTRAINT pk_grupo_muscular PRIMARY KEY (id_grupo),
    CONSTRAINT uq_grupo_nome     UNIQUE (nome)
) ENGINE = InnoDB;

-- 2.5 EXERCICIO - catalogo de exercicios (N:1 com GRUPO_MUSCULAR)
CREATE TABLE EXERCICIO (
    id_exercicio      INT          NOT NULL AUTO_INCREMENT,
    id_grupo          INT          NOT NULL,
    nome              VARCHAR(80)  NOT NULL,
    equipamento       VARCHAR(50)  NOT NULL,
    nivel_dificuldade VARCHAR(15)  NOT NULL,
    descricao         VARCHAR(255) NULL,
    CONSTRAINT pk_exercicio      PRIMARY KEY (id_exercicio),
    CONSTRAINT uq_exercicio_nome UNIQUE (nome),
    CONSTRAINT fk_exercicio_grupo FOREIGN KEY (id_grupo)
        REFERENCES GRUPO_MUSCULAR (id_grupo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_exercicio_nivel CHECK (nivel_dificuldade IN
        ('INICIANTE', 'INTERMEDIARIO', 'AVANCADO'))
) ENGINE = InnoDB;

-- 2.6 PLANO_TREINO - planos personalizados (1:N com ALUNO e PERSONAL_TRAINER)
CREATE TABLE PLANO_TREINO (
    id_plano    INT          NOT NULL AUTO_INCREMENT,
    id_aluno    INT          NOT NULL,
    id_personal INT          NOT NULL,
    nome        VARCHAR(80)  NOT NULL,
    descricao   VARCHAR(255) NULL,
    data_inicio DATE         NOT NULL,
    data_fim    DATE         NULL,
    status      VARCHAR(10)  NOT NULL DEFAULT 'ATIVO', -- DEFAULT 5
    CONSTRAINT pk_plano_treino PRIMARY KEY (id_plano),
    CONSTRAINT fk_plano_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_plano_personal FOREIGN KEY (id_personal)
        REFERENCES PERSONAL_TRAINER (id_personal)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_plano_status CHECK (status IN ('ATIVO', 'CONCLUIDO', 'CANCELADO')),
    CONSTRAINT ck_plano_datas  CHECK (data_fim IS NULL OR data_fim >= data_inicio)
) ENGINE = InnoDB;

-- 2.7 ITEM_PLANO - tabela associativa PLANO_TREINO x EXERCICIO (N:N)
CREATE TABLE ITEM_PLANO (
    id_item_plano     INT          NOT NULL AUTO_INCREMENT,
    id_plano          INT          NOT NULL,
    id_exercicio      INT          NOT NULL,
    ordem             TINYINT      NOT NULL,              -- posicao do exercicio no plano
    series            TINYINT      NOT NULL,
    repeticoes        TINYINT      NOT NULL,
    carga_sugerida_kg DECIMAL(5,1) NULL,
    descanso_segundos SMALLINT     NOT NULL DEFAULT 60,   -- DEFAULT 6
    CONSTRAINT pk_item_plano           PRIMARY KEY (id_item_plano),
    CONSTRAINT uq_item_plano_ordem     UNIQUE (id_plano, ordem),
    CONSTRAINT uq_item_plano_exercicio UNIQUE (id_plano, id_exercicio),
    CONSTRAINT fk_item_plano FOREIGN KEY (id_plano)
        REFERENCES PLANO_TREINO (id_plano)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_exercicio FOREIGN KEY (id_exercicio)
        REFERENCES EXERCICIO (id_exercicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_item_ordem      CHECK (ordem > 0),
    CONSTRAINT ck_item_series     CHECK (series > 0),
    CONSTRAINT ck_item_repeticoes CHECK (repeticoes > 0),
    CONSTRAINT ck_item_carga      CHECK (carga_sugerida_kg IS NULL OR carga_sugerida_kg >= 0),
    CONSTRAINT ck_item_descanso   CHECK (descanso_segundos >= 0)
) ENGINE = InnoDB;

-- 2.8 AULA - agendamento e controle das aulas
CREATE TABLE AULA (
    id_aula     INT          NOT NULL AUTO_INCREMENT,
    id_aluno    INT          NOT NULL,
    id_personal INT          NOT NULL,
    data_aula   DATE         NOT NULL,
    hora_inicio TIME         NOT NULL,
    hora_fim    TIME         NOT NULL,
    local       VARCHAR(60)  NOT NULL,
    tipo_aula   VARCHAR(30)  NOT NULL,
    status      VARCHAR(10)  NOT NULL DEFAULT 'AGENDADA', -- DEFAULT 7
    observacoes VARCHAR(255) NULL,
    CONSTRAINT pk_aula PRIMARY KEY (id_aula),
    CONSTRAINT fk_aula_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_aula_personal FOREIGN KEY (id_personal)
        REFERENCES PERSONAL_TRAINER (id_personal)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_aula_horario CHECK (hora_fim > hora_inicio),
    CONSTRAINT ck_aula_status  CHECK (status IN
        ('AGENDADA', 'REALIZADA', 'CANCELADA', 'FALTOU'))
) ENGINE = InnoDB;

-- 2.9 AVALIACAO_FISICA - avaliacoes periodicas
-- O IMC nao e armazenado (atributo derivado, calculado nas consultas).
CREATE TABLE AVALIACAO_FISICA (
    id_avaliacao       INT          NOT NULL AUTO_INCREMENT,
    id_aluno           INT          NOT NULL,
    id_personal        INT          NOT NULL,
    data_avaliacao     DATE         NOT NULL,
    peso_kg            DECIMAL(5,2) NOT NULL,
    altura_m           DECIMAL(3,2) NOT NULL,
    percentual_gordura DECIMAL(4,1) NULL,
    cintura_cm         DECIMAL(5,1) NULL,
    observacoes        VARCHAR(255) NULL,
    CONSTRAINT pk_avaliacao PRIMARY KEY (id_avaliacao),
    CONSTRAINT fk_avaliacao_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_avaliacao_personal FOREIGN KEY (id_personal)
        REFERENCES PERSONAL_TRAINER (id_personal)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_avaliacao_peso    CHECK (peso_kg > 0),
    CONSTRAINT ck_avaliacao_altura  CHECK (altura_m > 0),
    CONSTRAINT ck_avaliacao_gordura CHECK (percentual_gordura IS NULL
        OR percentual_gordura BETWEEN 3 AND 60),
    CONSTRAINT ck_avaliacao_cintura CHECK (cintura_cm IS NULL OR cintura_cm > 0)
) ENGINE = InnoDB;

-- 2.10 PAGAMENTO - controle financeiro (mensalidades)
CREATE TABLE PAGAMENTO (
    id_pagamento    INT           NOT NULL AUTO_INCREMENT,
    id_aluno        INT           NOT NULL,
    referencia_mes  CHAR(7)       NOT NULL,                  -- formato AAAA-MM
    valor           DECIMAL(8,2)  NOT NULL,
    data_vencimento DATE          NOT NULL,
    data_pagamento  DATE          NULL,                      -- preenchida somente quando pago
    forma_pagamento VARCHAR(20)   NULL,
    status          VARCHAR(10)   NOT NULL DEFAULT 'PENDENTE', -- DEFAULT 8
    CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
    CONSTRAINT uq_pagamento_mes UNIQUE (id_aluno, referencia_mes),
    CONSTRAINT fk_pagamento_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_pagamento_referencia CHECK
        (referencia_mes REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_pagamento_valor  CHECK (valor > 0),
    CONSTRAINT ck_pagamento_status CHECK (status IN ('PENDENTE', 'PAGO', 'ATRASADO')),
    CONSTRAINT ck_pagamento_forma  CHECK (forma_pagamento IS NULL OR forma_pagamento IN
        ('PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO', 'DINHEIRO', 'TRANSFERENCIA')),
    -- Regra de negocio RN10: pagamento quitado exige data de pagamento.
    CONSTRAINT ck_pagamento_quitado CHECK (status <> 'PAGO' OR data_pagamento IS NOT NULL)
) ENGINE = InnoDB;

-- 2.11 REGISTRO_TREINO - historico de execucao (N:N ALUNO x EXERCICIO)
CREATE TABLE REGISTRO_TREINO (
    id_registro          INT           NOT NULL AUTO_INCREMENT,
    id_aluno             INT           NOT NULL,
    id_exercicio         INT           NOT NULL,
    data_execucao        DATE          NOT NULL,
    series_realizadas    TINYINT       NOT NULL,
    repeticoes_realizadas SMALLINT     NOT NULL,             -- media de repeticoes por serie
    carga_kg             DECIMAL(5,1)  NOT NULL DEFAULT 0,   -- DEFAULT 9
    observacoes          VARCHAR(255)  NULL,
    CONSTRAINT pk_registro_treino PRIMARY KEY (id_registro),
    CONSTRAINT fk_registro_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_registro_exercicio FOREIGN KEY (id_exercicio)
        REFERENCES EXERCICIO (id_exercicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_registro_series     CHECK (series_realizadas > 0),
    CONSTRAINT ck_registro_repeticoes CHECK (repeticoes_realizadas > 0),
    CONSTRAINT ck_registro_carga      CHECK (carga_kg >= 0)
) ENGINE = InnoDB;

-- 3. INDICES COMPLEMENTARES
-- O InnoDB ja cria indices automaticamente para as chaves estrangeiras.
-- Estes dois atendem filtros frequentes nas consultas do sistema.
CREATE INDEX idx_aula_data            ON AULA (data_aula);
CREATE INDEX idx_pagamento_status_venc ON PAGAMENTO (status, data_vencimento);

-- 4. CONFERENCIA (opcional): lista as 11 tabelas criadas
SHOW TABLES;
```

## Apêndice B – Implementação física (DDL)

### B.1 Ambiente e convenções

O script 01_criacao_banco.sql cria o banco personal_trainer_db com conjunto de caracteres utf8mb4 e ordenação utf8mb4_unicode_ci, que garantem suporte completo a acentos e caracteres especiais, e as onze tabelas com o mecanismo InnoDB. As tabelas são criadas em ordem que respeita as dependências das chaves estrangeiras: primeiro as que não referenciam outras (PERSONAL_TRAINER, ALUNO e GRUPO_MUSCULAR) e depois as dependentes. O script começa com DROP DATABASE IF EXISTS, o que permite reexecutá-lo do zero, e por isso apaga todos os dados do banco ao ser executado. Nomes de tabelas, colunas e restrições seguem convenções uniformes: tabelas em maiúsculas, colunas em minúsculas com sublinhado e restrições com prefixos pk\_, fk\_, uq\_ e ck\_.

### B.2 Restrições de integridade

**Quadro 36 – Restrições declaradas no script de criação**

| **Tipo de restrição**  | **Quantidade**     | **Aplicação**                                                                                                                                                            |
|------------------------|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| PRIMARY KEY            | 11                 | Uma em cada tabela, do tipo INT AUTO_INCREMENT (em PERFIL_ALUNO, herdada de ALUNO).                                                                                      |
| FOREIGN KEY            | 13                 | Todas com ON DELETE e ON UPDATE explícitos (Quadro 4).                                                                                                                   |
| UNIQUE                 | 10                 | CPF, e-mail e CREF; nomes de grupo e de exercício; pares (id_plano, ordem), (id_plano, id_exercicio) e (id_aluno, referencia_mes).                                       |
| CHECK                  | 31                 | Formato de CPF e de referência de mês; domínios de status, sexo, objetivo, nível e forma de pagamento; valores positivos; horários; datas; e regra de pagamento quitado. |
| DEFAULT                | 9                  | Status em cinco tabelas, data de cadastro, frequência semanal desejada, descanso e carga.                                                                                |
| NOT NULL               | Conforme o domínio | Em todo campo cuja ausência não faz sentido; as exceções são as colunas descritas como opcionais no dicionário de dados.                                                 |
| Índices complementares | 2                  | idx_aula_data (data_aula) e idx_pagamento_status_venc (status, data_vencimento).                                                                                         |

Fonte: elaborado pelos autores (2026).

### B.3 Validação executada

Após a criação, o script foi validado no MySQL 8.0.46. O Quadro 37 registra os resultados, incluindo testes que confirmam que as restrições rejeitam dados inválidos.

**Quadro 37 – Validação do script de criação do banco**

| **Item**                                | **Resultado**                                  |
|-----------------------------------------|------------------------------------------------|
| Execução do script no MySQL 8.0.46      | Concluída sem erros, 11 tabelas criadas        |
| Chaves estrangeiras                     | 13, com as políticas do Quadro 4               |
| Constraints CHECK                       | 31                                             |
| Colunas com DEFAULT                     | 9                                              |
| Teste: CPF inválido                     | Rejeitado pela constraint ck_aluno_cpf         |
| Teste: valor_hora negativo              | Rejeitado pela constraint ck_personal_valor    |
| Teste: aula com aluno inexistente       | Rejeitada pela chave estrangeira fk_aula_aluno |
| Teste: aluno sem status e data_cadastro | Recebeu ATIVO e a data atual (DEFAULT)         |

Fonte: elaborado pelos autores (2026).

### B.4 Acréscimos em relação ao modelo lógico

Durante a implementação, três restrições foram acrescentadas ao modelo lógico inicial:

1)  CHECK de formato nos CPFs (onze dígitos) e em referencia_mes (AAAA-MM);

2)  CHECK em objetivo, com códigos sem acento e em maiúsculas, para manter as consultas por objetivo consistentes;

3)  CHECK em forma_pagamento, permitindo nulo enquanto o pagamento está pendente.

Foi acrescentada ainda a restrição ck_pagamento_quitado, que implementa a regra RN10: uma mensalidade com status PAGO exige data de pagamento preenchida.

### B.5 Índices complementares

O InnoDB cria índices automaticamente para as chaves estrangeiras. Dois índices foram acrescentados para atender a filtros frequentes das consultas: idx_aula_data, sobre a data da aula, e idx_pagamento_status_venc, sobre o status e o vencimento do pagamento, usado na identificação de mensalidades em aberto (Consulta Q03). O script completo está no Apêndice A.

## Apêndice C – Povoamento do banco (DML)

### C.1 Critérios

O banco foi povoado por instruções INSERT INTO, com no mínimo quinze registros em cada tabela, inclusive nas tabelas associativas. Os dados são fictícios, porém plausíveis e coerentes com o domínio: nomes, e-mails e telefones verossímeis, exercícios reais do universo da musculação e do treino funcional, planos com séries e repetições compatíveis, mensalidades com valores usuais e datas que cobrem os meses de agosto a novembro de 2026. Não foram usados registros artificiais como “teste1” ou “aaa”.

A massa de dados foi construída para que todas as consultas produzam resultados não vazios e significativos. Há 20 alunos e 80 mensalidades (uma por aluno em cada um dos quatro meses), de modo que a consulta de faturamento mensal mostra tanto meses totalmente quitados quanto meses com valores em aberto. As tabelas associativas refletem distribuição realista: alguns exercícios aparecem em vários planos e alguns planos reúnem vários exercícios, e o mesmo aluno repete o mesmo exercício em datas diferentes em REGISTRO_TREINO.

### C.2 Ordem de inserção

A ordem de inserção respeita a dependência entre as tabelas, para que nenhuma chave estrangeira aponte para registro inexistente. O Quadro 38 apresenta a sequência.

**Quadro 38 – Ordem de povoamento das tabelas**

| **Ordem** | **Tabela**       | **Depende de**           |
|-----------|------------------|--------------------------|
| 1         | PERSONAL_TRAINER | Nenhuma tabela           |
| 2         | ALUNO            | Nenhuma tabela           |
| 3         | GRUPO_MUSCULAR   | Nenhuma tabela           |
| 4         | PERFIL_ALUNO     | ALUNO                    |
| 5         | EXERCICIO        | GRUPO_MUSCULAR           |
| 6         | PLANO_TREINO     | ALUNO e PERSONAL_TRAINER |
| 7         | ITEM_PLANO       | PLANO_TREINO e EXERCICIO |
| 8         | AULA             | ALUNO e PERSONAL_TRAINER |
| 9         | AVALIACAO_FISICA | ALUNO e PERSONAL_TRAINER |
| 10        | PAGAMENTO        | ALUNO                    |
| 11        | REGISTRO_TREINO  | ALUNO e EXERCICIO        |

Fonte: elaborado pelos autores (2026).

