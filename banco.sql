
DROP DATABASE IF EXISTS personal_trainer_db;


CREATE DATABASE personal_trainer_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE personal_trainer_db;


CREATE TABLE PERSONAL_TRAINER (
    id_personal   INT            NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(100)   NOT NULL,
    cpf           CHAR(11)       NOT NULL,                 
    email         VARCHAR(100)   NOT NULL,
    telefone      VARCHAR(15)    NOT NULL,
    cref          VARCHAR(15)    NOT NULL,                 
    especialidade VARCHAR(60)    NULL,
    valor_hora    DECIMAL(8,2)   NOT NULL,
    status        VARCHAR(10)    NOT NULL DEFAULT 'ATIVO', 
    CONSTRAINT pk_personal        PRIMARY KEY (id_personal),
    CONSTRAINT uq_personal_cpf    UNIQUE (cpf),
    CONSTRAINT uq_personal_email  UNIQUE (email),
    CONSTRAINT uq_personal_cref   UNIQUE (cref),
    CONSTRAINT ck_personal_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_personal_valor  CHECK (valor_hora > 0),
    CONSTRAINT ck_personal_status CHECK (status IN ('ATIVO', 'INATIVO'))
) ENGINE = InnoDB;


CREATE TABLE ALUNO (
    id_aluno        INT           NOT NULL AUTO_INCREMENT,
    nome            VARCHAR(100)  NOT NULL,
    cpf             CHAR(11)      NOT NULL,
    email           VARCHAR(100)  NOT NULL,
    telefone        VARCHAR(15)   NOT NULL,
    data_nascimento DATE          NOT NULL,
    sexo            CHAR(1)       NOT NULL,                       
    data_cadastro   DATE          NOT NULL DEFAULT (CURRENT_DATE), 
    status          VARCHAR(10)   NOT NULL DEFAULT 'ATIVO',        
    CONSTRAINT pk_aluno        PRIMARY KEY (id_aluno),
    CONSTRAINT uq_aluno_cpf    UNIQUE (cpf),
    CONSTRAINT uq_aluno_email  UNIQUE (email),
    CONSTRAINT ck_aluno_cpf    CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT ck_aluno_sexo   CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT ck_aluno_status CHECK (status IN ('ATIVO', 'INATIVO'))
) ENGINE = InnoDB;


CREATE TABLE PERFIL_ALUNO (
    id_aluno                    INT           NOT NULL,
    objetivo                    VARCHAR(40)   NOT NULL,
    nivel_experiencia           VARCHAR(15)   NOT NULL,
    restricoes_medicas          VARCHAR(255)  NULL,
    contato_emergencia          VARCHAR(100)  NOT NULL,
    telefone_emergencia         VARCHAR(15)   NOT NULL,
    frequencia_semanal_desejada TINYINT       NOT NULL DEFAULT 3, -- DEFAULT 4
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


CREATE TABLE GRUPO_MUSCULAR (
    id_grupo  INT           NOT NULL AUTO_INCREMENT,
    nome      VARCHAR(40)   NOT NULL,
    descricao VARCHAR(150)  NULL,
    CONSTRAINT pk_grupo_muscular PRIMARY KEY (id_grupo),
    CONSTRAINT uq_grupo_nome     UNIQUE (nome)
) ENGINE = InnoDB;


CREATE TABLE EXERCICIO (
    id_exercicio      INT           NOT NULL AUTO_INCREMENT,
    id_grupo          INT           NOT NULL,
    nome              VARCHAR(80)   NOT NULL,
    equipamento       VARCHAR(50)   NOT NULL,
    nivel_dificuldade VARCHAR(15)   NOT NULL,
    descricao         VARCHAR(255)  NULL,
    CONSTRAINT pk_exercicio PRIMARY KEY (id_exercicio),
    CONSTRAINT uq_exercicio_nome UNIQUE (nome),
    CONSTRAINT fk_exercicio_grupo FOREIGN KEY (id_grupo)
        REFERENCES GRUPO_MUSCULAR (id_grupo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_exercicio_nivel CHECK (nivel_dificuldade IN
        ('INICIANTE', 'INTERMEDIARIO', 'AVANCADO'))
) ENGINE = InnoDB;


CREATE TABLE PLANO_TREINO (
    id_plano    INT           NOT NULL AUTO_INCREMENT,
    id_aluno    INT           NOT NULL,
    id_personal INT           NOT NULL,
    nome        VARCHAR(80)   NOT NULL,
    descricao   VARCHAR(255)  NULL,
    data_inicio DATE          NOT NULL,
    data_fim    DATE          NULL,
    status      VARCHAR(10)   NOT NULL DEFAULT 'ATIVO',  -- DEFAULT 5
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


CREATE TABLE ITEM_PLANO (
    id_item_plano     INT            NOT NULL AUTO_INCREMENT,
    id_plano          INT            NOT NULL,
    id_exercicio      INT            NOT NULL,
    ordem             TINYINT        NOT NULL,              
    series            TINYINT        NOT NULL,
    repeticoes        TINYINT        NOT NULL,
    carga_sugerida_kg DECIMAL(5,1)   NULL,
    descanso_segundos SMALLINT       NOT NULL DEFAULT 60,   
    CONSTRAINT pk_item_plano PRIMARY KEY (id_item_plano),
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


CREATE TABLE AULA (
    id_aula     INT           NOT NULL AUTO_INCREMENT,
    id_aluno    INT           NOT NULL,
    id_personal INT           NOT NULL,
    data_aula   DATE          NOT NULL,
    hora_inicio TIME          NOT NULL,
    hora_fim    TIME          NOT NULL,
    local       VARCHAR(60)   NOT NULL,
    tipo_aula   VARCHAR(30)   NOT NULL,
    status      VARCHAR(10)   NOT NULL DEFAULT 'AGENDADA',  -- DEFAULT 7
    observacoes VARCHAR(255)  NULL,
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


CREATE TABLE AVALIACAO_FISICA (
    id_avaliacao       INT           NOT NULL AUTO_INCREMENT,
    id_aluno           INT           NOT NULL,
    id_personal        INT           NOT NULL,
    data_avaliacao     DATE          NOT NULL,
    peso_kg            DECIMAL(5,2)  NOT NULL,
    altura_m           DECIMAL(3,2)  NOT NULL,
    percentual_gordura DECIMAL(4,1)  NULL,
    cintura_cm         DECIMAL(5,1)  NULL,
    observacoes        VARCHAR(255)  NULL,
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


CREATE TABLE REGISTRO_TREINO (
    id_registro           INT           NOT NULL AUTO_INCREMENT,
    id_aluno              INT           NOT NULL,
    id_exercicio          INT           NOT NULL,
    data_execucao         DATE          NOT NULL,
    series_realizadas     TINYINT       NOT NULL,
    repeticoes_realizadas SMALLINT      NOT NULL,  -- media de repeticoes por serie
    carga_kg              DECIMAL(5,1)  NOT NULL DEFAULT 0,  -- DEFAULT 9
    observacoes           VARCHAR(255)  NULL,
    CONSTRAINT pk_registro_treino PRIMARY KEY (id_registro),
    CONSTRAINT fk_registro_aluno FOREIGN KEY (id_aluno)
        REFERENCES ALUNO (id_aluno)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_registro_exercicio FOREIGN KEY (id_exercicio)
        REFERENCES EXERCICIO (id_exercicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_registro_series      CHECK (series_realizadas > 0),
    CONSTRAINT ck_registro_repeticoes  CHECK (repeticoes_realizadas > 0),
    CONSTRAINT ck_registro_carga       CHECK (carga_kg >= 0)
) ENGINE = InnoDB;


CREATE INDEX idx_aula_data ON AULA (data_aula);
CREATE INDEX idx_pagamento_status_venc ON PAGAMENTO (status, data_vencimento);


SHOW TABLES;


USE personal_trainer_db;


INSERT INTO PERSONAL_TRAINER (id_personal, nome, cpf, email, telefone, cref, especialidade, valor_hora, status) VALUES
(1, 'Ricardo Albuquerque Neves', '58813998627', 'ricardo.neves@studiofit.com.br', '31997309114', '025613-G/MG', 'Musculação e hipertrofia', '120.00', 'ATIVO'),
(2, 'Patrícia Medeiros Salles', '70753645530', 'patricia.salles@outlook.com', '38951884472', '022851-G/MG', 'Emagrecimento e condicionamento', '110.00', 'ATIVO'),
(3, 'André Luiz Cardoso', '94055761600', 'andre.cardoso@studiofit.com.br', '31916897684', '094514-G/MG', 'Reabilitação e pós-lesão', '140.00', 'ATIVO'),
(4, 'Tatiane Borges Freire', '97880932054', 'tatiane.freire@studiofit.com.br', '38996727317', '065045-G/MG', 'Treinamento funcional', '100.00', 'ATIVO'),
(5, 'Felipe Augusto Lacerda', '78486488770', 'felipe.lacerda@outlook.com', '31934400297', '098382-G/MG', 'Força e powerlifting', '130.00', 'ATIVO'),
(6, 'Vanessa Pires Coelho', '75347787600', 'vanessa.coelho@studiofit.com.br', '38945717847', '078536-G/MG', 'Gestantes e saúde da mulher', '120.00', 'ATIVO'),
(7, 'Eduardo Siqueira Prado', '67147513622', 'eduardo.prado@gmail.com', '31901079819', '033992-G/MG', 'Idosos e qualidade de vida', '105.00', 'ATIVO'),
(8, 'Luciana Xavier Moura', '31908452048', 'luciana.moura@outlook.com', '31928379298', '036056-G/MG', 'Emagrecimento', '95.00', 'ATIVO'),
(9, 'Rodrigo Mattos Vasconcelos', '16229486610', 'rodrigo.vasconcelos@gmail.com', '38960161055', '048100-G/MG', 'Condicionamento esportivo', '125.00', 'ATIVO'),
(10, 'Daniela Furtado Aragão', '08754751756', 'daniela.aragao@outlook.com', '38929836957', '013380-G/MG', 'Glúteos e membros inferiores', '100.00', 'ATIVO'),
(11, 'Marcelo Tavares Quintão', '31860320830', 'marcelo.quintao@gmail.com', '31937028382', '088409-G/MG', 'Hipertrofia', '115.00', 'ATIVO'),
(12, 'Cláudia Regina Dantas', '26468616484', 'claudia.dantas@gmail.com', '38924776472', '031022-G/MG', 'Mobilidade e alongamento', '90.00', 'ATIVO'),
(13, 'Henrique Bastos Oliveira', '87718841308', 'henrique.oliveira@gmail.com', '38917568205', '052701-G/MG', 'Treinamento ao ar livre', '85.00', 'ATIVO'),
(14, 'Simone Rangel Peixoto', '58983194847', 'simone.peixoto@studiofit.com.br', '38994948214', '030546-G/MG', 'Reabilitação', '110.00', 'INATIVO'),
(15, 'Gilberto Nascimento Leal', '62105218512', 'gilberto.leal@outlook.com', '38945244106', '022639-G/MG', 'Musculação', '80.00', 'INATIVO');


INSERT INTO ALUNO (id_aluno, nome, cpf, email, telefone, data_nascimento, sexo, data_cadastro, status) VALUES
(1, 'Mariana Souza Oliveira', '46001304130', 'mariana.oliveira@gmail.com', '38957990659', '1994-03-12', 'F', '2025-11-04', 'ATIVO'),
(2, 'Rafael Almeida Costa', '06045414659', 'rafael.costa@hotmail.com', '38985380129', '1990-07-25', 'M', '2025-12-02', 'ATIVO'),
(3, 'Juliana Ferreira Lima', '92566636354', 'juliana.lima@outlook.com', '38980886423', '1988-11-03', 'F', '2026-01-12', 'ATIVO'),
(4, 'Carlos Eduardo Menezes', '12808458568', 'carlos.menezes@gmail.com', '38937038265', '1975-05-18', 'M', '2026-01-20', 'ATIVO'),
(5, 'Fernanda Rocha Martins', '94326270551', 'fernanda.martins@uol.com.br', '31902145842', '1999-09-30', 'F', '2026-02-09', 'ATIVO'),
(6, 'Bruno Henrique Nogueira', '68828112611', 'bruno.nogueira@hotmail.com', '38940932448', '1996-01-14', 'M', '2026-02-16', 'ATIVO'),
(7, 'Patrícia Gomes Barbosa', '82802582216', 'patricia.barbosa@gmail.com', '38980515438', '1969-12-08', 'F', '2026-03-02', 'ATIVO'),
(8, 'Lucas Pereira Duarte', '94157718879', 'lucas.duarte@outlook.com', '38979511174', '2001-04-22', 'M', '2026-03-09', 'ATIVO'),
(9, 'Camila Vieira Araújo', '65237355676', 'camila.araujo@uol.com.br', '31932792645', '1992-06-17', 'F', '2026-03-23', 'ATIVO'),
(10, 'Marcos Antônio Teixeira', '28144976690', 'marcos.teixeira@gmail.com', '38965178836', '1963-08-29', 'M', '2026-04-06', 'ATIVO'),
(11, 'Aline Cristina Batista', '59967750006', 'aline.batista@outlook.com', '38945037849', '1985-02-11', 'F', '2026-04-13', 'ATIVO'),
(12, 'Thiago Moreira Santos', '37392419692', 'thiago.santos@uol.com.br', '38910460288', '1993-10-05', 'M', '2026-05-04', 'ATIVO'),
(13, 'Beatriz Carvalho Pinto', '54072075400', 'beatriz.pinto@yahoo.com.br', '38954864390', '1997-07-19', 'F', '2026-05-18', 'ATIVO'),
(14, 'Gustavo Ribeiro Freitas', '95755521808', 'gustavo.freitas@outlook.com', '38988619307', '1980-03-27', 'M', '2026-06-01', 'ATIVO'),
(15, 'Larissa Monteiro Cunha', '28556898300', 'larissa.cunha@outlook.com', '38922900442', '2000-12-01', 'F', '2026-08-10', 'ATIVO'),
(16, 'Roberto Carlos Figueiredo', '26978043826', 'roberto.figueiredo@hotmail.com', '38976252807', '1958-09-14', 'M', '2025-10-13', 'INATIVO'),
(17, 'Renata Lopes Machado', '31663233764', 'renata.machado@outlook.com', '38928667534', '1991-05-06', 'F', '2025-11-24', 'INATIVO'),
(18, 'Diego Fernandes Rezende', '59212363652', 'diego.rezende@gmail.com', '38944560787', '1998-08-23', 'M', '2026-01-26', 'INATIVO');


INSERT INTO PERFIL_ALUNO (id_aluno, objetivo, nivel_experiencia, restricoes_medicas, contato_emergencia, telefone_emergencia, frequencia_semanal_desejada) VALUES
(1, 'EMAGRECIMENTO', 'INICIANTE', NULL, 'Marta Oliveira (mãe)', '31961584645', 3),
(2, 'HIPERTROFIA', 'INTERMEDIARIO', NULL, 'Sandra Costa (esposa)', '38902859406', 5),
(3, 'CONDICIONAMENTO', 'INICIANTE', 'Asma leve controlada; usa bombinha antes do treino', 'Paulo Lima (marido)', '38948764529', 3),
(4, 'EMAGRECIMENTO', 'INICIANTE', 'Hipertensão controlada com medicação', 'Marta Menezes (esposa)', '38953557787', 3),
(5, 'HIPERTROFIA', 'INTERMEDIARIO', NULL, 'Elaine Martins (mãe)', '38908394906', 4),
(6, 'FORCA', 'AVANCADO', 'Tendinite leve no ombro direito', 'Antônio Nogueira (pai)', '38926309765', 4),
(7, 'QUALIDADE_DE_VIDA', 'INICIANTE', 'Osteopenia; evitar exercícios de alto impacto', 'Marta Barbosa (filha)', '38921571164', 2),
(8, 'HIPERTROFIA', 'INICIANTE', NULL, 'Antônio Duarte (pai)', '38925688557', 4),
(9, 'CONDICIONAMENTO', 'INTERMEDIARIO', NULL, 'Sandra Araújo (irmã)', '38947428435', 3),
(10, 'REABILITACAO', 'INICIANTE', 'Hérnia de disco L4-L5; liberado pelo ortopedista para treinar', 'Luciana Teixeira (esposa)', '38906204842', 3),
(11, 'EMAGRECIMENTO', 'INICIANTE', NULL, 'Wagner Batista (marido)', '38918380125', 4),
(12, 'EMAGRECIMENTO', 'INTERMEDIARIO', NULL, 'Marta Santos (mãe)', '31955559747', 4),
(13, 'CONDICIONAMENTO', 'INTERMEDIARIO', NULL, 'Sérgio Pinto (pai)', '38988479188', 3),
(14, 'HIPERTROFIA', 'INTERMEDIARIO', 'Lesão antiga de menisco no joelho esquerdo', 'Marta Freitas (esposa)', '38968828347', 4),
(15, 'REABILITACAO', 'INICIANTE', 'Recuperação de cirurgia no ligamento do joelho direito; liberada pela fisioterapeuta', 'Marta Cunha (mãe)', '38985272202', 2),
(16, 'QUALIDADE_DE_VIDA', 'INICIANTE', 'Diabetes tipo 2 controlada com medicação', 'Sandra Figueiredo (filha)', '38915945028', 2),
(17, 'EMAGRECIMENTO', 'INICIANTE', NULL, 'Wagner Machado (irmão)', '31989713311', 3),
(18, 'HIPERTROFIA', 'INTERMEDIARIO', NULL, 'Antônio Rezende (pai)', '38972128357', 4);


INSERT INTO GRUPO_MUSCULAR (id_grupo, nome, descricao) VALUES
(1, 'Peitoral', 'Músculos peitorais maior e menor, responsáveis pelos movimentos de empurrar'),
(2, 'Costas', 'Grande dorsal, romboides e redondo maior, responsáveis pelos movimentos de puxar'),
(3, 'Ombros', 'Deltoides anterior, lateral e posterior'),
(4, 'Bíceps', 'Bíceps braquial e braquial, na parte anterior do braço'),
(5, 'Tríceps', 'Tríceps braquial, na parte posterior do braço'),
(6, 'Antebraço', 'Flexores e extensores do punho e dos dedos'),
(7, 'Quadríceps', 'Músculos da parte anterior da coxa'),
(8, 'Posterior de Coxa', 'Isquiotibiais: bíceps femoral, semitendíneo e semimembranáceo'),
(9, 'Glúteos', 'Glúteo máximo, médio e mínimo'),
(10, 'Panturrilhas', 'Gastrocnêmio e sóleo'),
(11, 'Abdômen', 'Reto abdominal, oblíquos e transverso do abdômen'),
(12, 'Lombar', 'Eretores da espinha e músculos estabilizadores da coluna'),
(13, 'Trapézio', 'Porções superior, média e inferior do trapézio'),
(14, 'Adutores e Abdutores', 'Músculos da face interna e externa do quadril e da coxa'),
(15, 'Cardio e Corpo Inteiro', 'Exercícios globais de condicionamento cardiorrespiratório');


INSERT INTO EXERCICIO (id_exercicio, id_grupo, nome, equipamento, nivel_dificuldade, descricao) VALUES
(1, 1, 'Supino reto com barra', 'Barra e banco reto', 'INTERMEDIARIO', 'Empurrar a barra a partir do peito deitado no banco reto'),
(2, 1, 'Supino inclinado com halteres', 'Halteres e banco inclinado', 'INTERMEDIARIO', 'Empurrar os halteres com o banco inclinado, enfatizando a porção superior do peitoral'),
(3, 1, 'Crucifixo na máquina (peck deck)', 'Máquina peck deck', 'INICIANTE', 'Aproximar os braços à frente do corpo com apoio da máquina'),
(4, 2, 'Puxada frontal na polia', 'Polia alta', 'INICIANTE', 'Puxar a barra da polia alta até a altura do queixo'),
(5, 2, 'Remada curvada com barra', 'Barra', 'AVANCADO', 'Com o tronco inclinado, puxar a barra em direção ao abdômen'),
(6, 2, 'Remada baixa no cabo', 'Polia baixa', 'INICIANTE', 'Sentado, puxar o triângulo em direção ao abdômen'),
(7, 3, 'Desenvolvimento com halteres', 'Halteres e banco', 'INTERMEDIARIO', 'Empurrar os halteres acima da cabeça, sentado'),
(8, 3, 'Elevação lateral com halteres', 'Halteres', 'INICIANTE', 'Elevar os braços lateralmente até a altura dos ombros'),
(9, 4, 'Rosca direta com barra', 'Barra reta', 'INICIANTE', 'Flexionar os cotovelos levando a barra até a altura do peito'),
(10, 4, 'Rosca alternada com halteres', 'Halteres', 'INICIANTE', 'Flexionar um braço de cada vez com os halteres'),
(11, 5, 'Tríceps pulley com corda', 'Polia alta e corda', 'INICIANTE', 'Estender os cotovelos puxando a corda para baixo'),
(12, 5, 'Tríceps testa com barra W', 'Barra W e banco', 'INTERMEDIARIO', 'Deitado, flexionar e estender os cotovelos com a barra sobre a testa'),
(13, 6, 'Rosca de punho com barra', 'Barra reta', 'INICIANTE', 'Flexionar os punhos com os antebraços apoiados'),
(14, 7, 'Agachamento livre com barra', 'Barra e rack', 'AVANCADO', 'Agachar com a barra apoiada nas costas'),
(15, 7, 'Leg press 45 graus', 'Máquina leg press', 'INICIANTE', 'Empurrar a plataforma com as pernas a partir de uma posição sentada inclinada'),
(16, 7, 'Cadeira extensora', 'Máquina extensora', 'INICIANTE', 'Estender os joelhos contra a resistência da máquina'),
(17, 8, 'Mesa flexora', 'Máquina flexora', 'INICIANTE', 'Deitado, flexionar os joelhos contra a resistência da máquina'),
(18, 8, 'Stiff com barra', 'Barra', 'INTERMEDIARIO', 'Flexionar o quadril mantendo as pernas quase estendidas e a coluna neutra'),
(19, 9, 'Elevação pélvica com barra', 'Barra e banco', 'INTERMEDIARIO', 'Com as costas apoiadas no banco, elevar o quadril com a barra sobre ele'),
(20, 9, 'Agachamento sumô com halter', 'Halter', 'INICIANTE', 'Agachar com os pés afastados e um halter entre as pernas'),
(21, 10, 'Panturrilha em pé no smith', 'Smith machine', 'INICIANTE', 'Elevar os calcanhares em pé com a barra sobre os ombros'),
(22, 10, 'Panturrilha sentado', 'Máquina de panturrilha sentado', 'INICIANTE', 'Elevar os calcanhares sentado contra a resistência da máquina'),
(23, 11, 'Abdominal supra no solo', 'Colchonete', 'INICIANTE', 'Flexionar o tronco elevando as escápulas do solo'),
(24, 11, 'Prancha isométrica', 'Colchonete', 'INTERMEDIARIO', 'Manter o corpo alinhado apoiado nos antebraços e na ponta dos pés'),
(25, 12, 'Extensão lombar no banco romano', 'Banco romano', 'INICIANTE', 'Estender o tronco no banco romano, fortalecendo a região lombar'),
(26, 13, 'Encolhimento com halteres', 'Halteres', 'INICIANTE', 'Elevar os ombros em direção às orelhas com os halteres'),
(27, 14, 'Cadeira abdutora', 'Máquina abdutora', 'INICIANTE', 'Afastar as pernas contra a resistência da máquina'),
(28, 14, 'Cadeira adutora', 'Máquina adutora', 'INICIANTE', 'Aproximar as pernas contra a resistência da máquina'),
(29, 15, 'Esteira - corrida intervalada', 'Esteira', 'INICIANTE', 'Tiros de 1 minuto em ritmo forte alternados com caminhada; cada série corresponde a um tiro'),
(30, 15, 'Remo ergométrico', 'Remo ergométrico', 'INTERMEDIARIO', 'Séries de 500 metros em ritmo moderado'),
(31, 15, 'Kettlebell swing', 'Kettlebell', 'INTERMEDIARIO', 'Balançar o kettlebell à frente do corpo com impulso do quadril');


INSERT INTO PLANO_TREINO (id_plano, id_aluno, id_personal, nome, descricao, data_inicio, data_fim, status) VALUES
(1, 1, 2, 'Circuito Full Body Iniciante', 'Circuito de corpo inteiro com máquinas, indicado para adaptação e gasto calórico', '2025-11-11', '2026-02-09', 'CONCLUIDO'),
(2, 1, 2, 'Emagrecimento Avançado', 'Treino de alta densidade combinando força e condicionamento para gasto calórico', '2026-02-15', NULL, 'ATIVO'),
(3, 2, 1, 'Hipertrofia A - Peito, Ombros e Tríceps', 'Treino de empurrar com foco em ganho de massa muscular da parte superior', '2025-12-09', NULL, 'ATIVO'),
(4, 2, 1, 'Hipertrofia B - Costas e Bíceps', 'Treino de puxar com foco em ganho de massa muscular de costas e braços', '2025-12-09', NULL, 'ATIVO'),
(5, 3, 4, 'Condicionamento Geral', 'Treino funcional para melhora do condicionamento cardiorrespiratório e resistência', '2026-01-19', NULL, 'ATIVO'),
(6, 4, 2, 'Circuito Full Body Iniciante', 'Circuito de corpo inteiro com máquinas, indicado para adaptação e gasto calórico', '2026-01-27', '2026-04-27', 'CONCLUIDO'),
(7, 4, 2, 'Emagrecimento Avançado', 'Treino de alta densidade combinando força e condicionamento para gasto calórico', '2026-05-03', '2026-10-30', 'ATIVO'),
(8, 5, 10, 'Glúteos e Pernas', 'Treino com ênfase em glúteos, posterior de coxa e estabilização do core', '2026-02-16', NULL, 'ATIVO'),
(9, 6, 5, 'Força Básica', 'Treino de força com os grandes movimentos básicos e cargas elevadas', '2026-02-23', NULL, 'ATIVO'),
(10, 7, 7, 'Mobilidade e Qualidade de Vida', 'Treino de baixa intensidade para manutenção de força, equilíbrio e autonomia', '2026-03-09', NULL, 'ATIVO'),
(11, 8, 11, 'Hipertrofia A - Peito, Ombros e Tríceps', 'Treino de empurrar com foco em ganho de massa muscular da parte superior', '2026-03-16', NULL, 'ATIVO'),
(12, 8, 11, 'Pernas e Posteriores', 'Treino de membros inferiores com ênfase em quadríceps e posterior de coxa', '2026-05-04', NULL, 'ATIVO'),
(13, 9, 4, 'Condicionamento Geral', 'Treino funcional para melhora do condicionamento cardiorrespiratório e resistência', '2026-03-30', NULL, 'ATIVO'),
(14, 10, 3, 'Reabilitação e Estabilidade', 'Treino de baixa carga para fortalecimento e estabilização de coluna e membros inferiores', '2026-04-13', NULL, 'ATIVO'),
(15, 11, 8, 'Circuito Full Body Iniciante', 'Circuito de corpo inteiro com máquinas, indicado para adaptação e gasto calórico', '2026-04-20', NULL, 'ATIVO'),
(16, 12, 9, 'Emagrecimento Avançado', 'Treino de alta densidade combinando força e condicionamento para gasto calórico', '2026-05-11', '2026-11-07', 'ATIVO'),
(17, 13, 13, 'Condicionamento Geral', 'Treino funcional para melhora do condicionamento cardiorrespiratório e resistência', '2026-05-25', '2026-11-21', 'ATIVO'),
(18, 14, 1, 'Hipertrofia A - Peito, Ombros e Tríceps', 'Treino de empurrar com foco em ganho de massa muscular da parte superior', '2026-06-08', '2026-12-05', 'ATIVO'),
(19, 15, 3, 'Reabilitação e Estabilidade', 'Treino de baixa carga para fortalecimento e estabilização de coluna e membros inferiores', '2026-08-17', '2027-02-13', 'ATIVO'),
(20, 16, 7, 'Mobilidade e Qualidade de Vida', 'Treino de baixa intensidade para manutenção de força, equilíbrio e autonomia', '2025-10-20', '2026-08-31', 'CANCELADO'),
(21, 17, 8, 'Circuito Full Body Iniciante', 'Circuito de corpo inteiro com máquinas, indicado para adaptação e gasto calórico', '2025-12-01', '2026-06-30', 'CANCELADO'),
(22, 18, 11, 'Hipertrofia A - Peito, Ombros e Tríceps', 'Treino de empurrar com foco em ganho de massa muscular da parte superior', '2026-02-02', '2026-09-30', 'CANCELADO');


INSERT INTO ITEM_PLANO (id_item_plano, id_plano, id_exercicio, ordem, series, repeticoes, carga_sugerida_kg, descanso_segundos) VALUES
(1, 1, 15, 1, 3, 15, '25.0', 60),
(2, 1, 3, 2, 3, 12, '10.5', 60),
(3, 1, 4, 3, 3, 12, '14.5', 60),
(4, 1, 16, 4, 3, 15, '12.5', 45),
(5, 1, 23, 5, 3, 20, NULL, 45),
(6, 1, 29, 6, 6, 1, NULL, 60),
(7, 2, 14, 1, 3, 15, '17.0', 60),
(8, 2, 2, 2, 3, 12, '7.5', 60),
(9, 2, 6, 3, 3, 12, '17.0', 60),
(10, 2, 31, 4, 4, 15, '6.5', 45),
(11, 2, 29, 5, 8, 1, NULL, 45),
(12, 2, 23, 6, 3, 20, NULL, 30),
(13, 3, 1, 1, 4, 10, '50.0', 90),
(14, 3, 2, 2, 4, 10, '20.0', 90),
(15, 3, 7, 3, 3, 12, '14.0', 75),
(16, 3, 8, 4, 3, 15, '8.0', 60),
(17, 3, 11, 5, 3, 12, '25.0', 60),
(18, 3, 12, 6, 3, 12, '20.0', 60),
(19, 4, 4, 1, 4, 10, '50.0', 90),
(20, 4, 5, 2, 4, 10, '40.0', 90),
(21, 4, 6, 3, 3, 12, '45.0', 75),
(22, 4, 9, 4, 3, 10, '25.0', 60),
(23, 4, 10, 5, 3, 12, '10.0', 60),
(24, 4, 26, 6, 3, 12, '20.0', 60),
(25, 4, 13, 7, 3, 15, '15.0', 45),
(26, 5, 29, 1, 6, 1, NULL, 60),
(27, 5, 31, 2, 4, 15, '5.0', 60),
(28, 5, 30, 3, 4, 1, NULL, 90),
(29, 5, 20, 4, 3, 15, '5.0', 45),
(30, 5, 24, 5, 3, 1, NULL, 45),
(31, 5, 23, 6, 3, 20, NULL, 30),
(32, 6, 15, 1, 3, 15, '42.0', 60),
(33, 6, 3, 2, 3, 12, '17.5', 60),
(34, 6, 4, 3, 3, 12, '24.5', 60),
(35, 6, 16, 4, 3, 15, '21.0', 45),
(36, 6, 23, 5, 3, 20, NULL, 45),
(37, 6, 29, 6, 6, 1, NULL, 60),
(38, 7, 14, 1, 3, 15, '28.0', 60),
(39, 7, 2, 2, 3, 12, '12.5', 60),
(40, 7, 6, 3, 3, 12, '28.0', 60),
(41, 7, 31, 4, 4, 15, '11.0', 45),
(42, 7, 29, 5, 8, 1, NULL, 45),
(43, 7, 23, 6, 3, 20, NULL, 30),
(44, 8, 19, 1, 4, 12, '30.0', 90),
(45, 8, 20, 2, 4, 12, '9.5', 75),
(46, 8, 27, 3, 3, 15, '24.0', 60),
(47, 8, 17, 4, 3, 12, '18.0', 60),
(48, 8, 18, 5, 3, 12, '18.0', 75),
(49, 8, 24, 6, 3, 1, NULL, 45),
(50, 9, 14, 1, 5, 5, '125.0', 180),
(51, 9, 1, 2, 5, 5, '100.0', 180),
(52, 9, 18, 3, 4, 6, '112.5', 150),
(53, 9, 5, 4, 4, 6, '87.5', 120),
(54, 9, 7, 5, 4, 8, '30.0', 90),
(55, 9, 24, 6, 3, 1, NULL, 60),
(56, 10, 15, 1, 3, 12, '17.0', 90),
(57, 10, 4, 2, 3, 12, '10.5', 90),
(58, 10, 16, 3, 3, 12, '8.5', 75),
(59, 10, 8, 4, 3, 12, '1.5', 60),
(60, 10, 22, 5, 3, 15, '8.5', 60),
(61, 10, 23, 6, 3, 12, NULL, 60),
(62, 11, 1, 1, 4, 10, '35.0', 90),
(63, 11, 2, 2, 4, 10, '14.0', 90),
(64, 11, 7, 3, 3, 12, '10.0', 75),
(65, 11, 8, 4, 3, 15, '5.5', 60),
(66, 11, 11, 5, 3, 12, '17.5', 60),
(67, 11, 12, 6, 3, 12, '14.0', 60),
(68, 12, 14, 1, 4, 10, '42.0', 120),
(69, 12, 15, 2, 4, 12, '84.0', 90),
(70, 12, 16, 3, 3, 12, '28.0', 60),
(71, 12, 17, 4, 3, 12, '24.5', 60),
(72, 12, 18, 5, 3, 10, '28.0', 90),
(73, 12, 21, 6, 4, 15, '28.0', 45),
(74, 13, 29, 1, 6, 1, NULL, 60),
(75, 13, 31, 2, 4, 15, '7.0', 60),
(76, 13, 30, 3, 4, 1, NULL, 90),
(77, 13, 20, 4, 3, 15, '7.0', 45),
(78, 13, 24, 5, 3, 1, NULL, 45),
(79, 13, 23, 6, 3, 20, NULL, 30),
(80, 14, 25, 1, 3, 12, NULL, 60),
(81, 14, 24, 2, 3, 1, NULL, 60),
(82, 14, 15, 3, 3, 15, '14.0', 75),
(83, 14, 28, 4, 3, 15, '9.0', 60),
(84, 14, 6, 5, 3, 12, '9.0', 60),
(85, 14, 23, 6, 3, 15, NULL, 45),
(86, 15, 15, 1, 3, 15, '25.0', 60),
(87, 15, 3, 2, 3, 12, '10.5', 60),
(88, 15, 4, 3, 3, 12, '14.5', 60),
(89, 15, 16, 4, 3, 15, '12.5', 45),
(90, 15, 23, 5, 3, 20, NULL, 45),
(91, 15, 29, 6, 6, 1, NULL, 60),
(92, 16, 14, 1, 3, 15, '40.0', 60),
(93, 16, 2, 2, 3, 12, '18.0', 60),
(94, 16, 6, 3, 3, 12, '40.0', 60),
(95, 16, 31, 4, 4, 15, '16.0', 45),
(96, 16, 29, 5, 8, 1, NULL, 45),
(97, 16, 23, 6, 3, 20, NULL, 30),
(98, 17, 29, 1, 6, 1, NULL, 60),
(99, 17, 31, 2, 4, 15, '7.0', 60),
(100, 17, 30, 3, 4, 1, NULL, 90),
(101, 17, 20, 4, 3, 15, '7.0', 45),
(102, 17, 24, 5, 3, 1, NULL, 45),
(103, 17, 23, 6, 3, 20, NULL, 30),
(104, 18, 1, 1, 4, 10, '50.0', 90),
(105, 18, 2, 2, 4, 10, '20.0', 90),
(106, 18, 7, 3, 3, 12, '14.0', 75),
(107, 18, 8, 4, 3, 15, '8.0', 60),
(108, 18, 11, 5, 3, 12, '25.0', 60),
(109, 18, 12, 6, 3, 12, '20.0', 60),
(110, 19, 25, 1, 3, 12, NULL, 60),
(111, 19, 24, 2, 3, 1, NULL, 60),
(112, 19, 15, 3, 3, 15, '8.5', 75),
(113, 19, 28, 4, 3, 15, '5.0', 60),
(114, 19, 6, 5, 3, 12, '5.0', 60),
(115, 19, 23, 6, 3, 15, NULL, 45),
(116, 20, 15, 1, 3, 12, '28.0', 90),
(117, 20, 4, 2, 3, 12, '17.5', 90),
(118, 20, 16, 3, 3, 12, '14.0', 75),
(119, 20, 8, 4, 3, 12, '2.0', 60),
(120, 20, 22, 5, 3, 15, '14.0', 60),
(121, 20, 23, 6, 3, 12, NULL, 60),
(122, 21, 15, 1, 3, 15, '25.0', 60),
(123, 21, 3, 2, 3, 12, '10.5', 60),
(124, 21, 4, 3, 3, 12, '14.5', 60),
(125, 21, 16, 4, 3, 15, '12.5', 45),
(126, 21, 23, 5, 3, 20, NULL, 45),
(127, 21, 29, 6, 6, 1, NULL, 60),
(128, 22, 1, 1, 4, 10, '50.0', 90),
(129, 22, 2, 2, 4, 10, '20.0', 90),
(130, 22, 7, 3, 3, 12, '14.0', 75),
(131, 22, 8, 4, 3, 15, '8.0', 60),
(132, 22, 11, 5, 3, 12, '25.0', 60),
(133, 22, 12, 6, 3, 12, '20.0', 60);


INSERT INTO AULA (id_aula, id_aluno, id_personal, data_aula, hora_inicio, hora_fim, local, tipo_aula, status, observacoes) VALUES
(1, 17, 8, '2026-06-02', '19:00:00', '20:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(2, 17, 8, '2026-06-09', '19:00:00', '20:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', 'Foco em técnica de execução'),
(3, 17, 8, '2026-06-16', '19:00:00', '20:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', 'Ajuste de postura nos exercícios de costas'),
(4, 17, 8, '2026-06-23', '19:00:00', '20:00:00', 'Academia Vitalle', 'Cardio', 'REALIZADA', 'Ajuste de postura nos exercícios de costas'),
(5, 16, 7, '2026-08-03', '17:00:00', '17:45:00', 'Academia Corpo e Mente', 'Alongamento e mobilidade', 'REALIZADA', 'Ênfase em mobilidade e alongamento'),
(6, 16, 7, '2026-08-10', '17:00:00', '17:45:00', 'Academia Corpo e Mente', 'Alongamento e mobilidade', 'REALIZADA', NULL),
(7, 16, 7, '2026-08-17', '17:00:00', '17:45:00', 'Academia Corpo e Mente', 'Alongamento e mobilidade', 'REALIZADA', NULL),
(8, 16, 7, '2026-08-24', '17:00:00', '17:45:00', 'Academia Corpo e Mente', 'Alongamento e mobilidade', 'FALTOU', 'Aluno não compareceu e não avisou'),
(9, 18, 11, '2026-09-02', '06:00:00', '07:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Boa evolução de carga em relação à semana anterior'),
(10, 18, 11, '2026-09-09', '06:00:00', '07:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Ajuste de postura nos exercícios de costas'),
(11, 18, 11, '2026-09-16', '06:00:00', '07:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', NULL),
(12, 18, 11, '2026-09-23', '06:00:00', '07:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Foco em técnica de execução'),
(13, 14, 1, '2026-10-05', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'FALTOU', 'Aluno não compareceu e não avisou'),
(14, 5, 10, '2026-10-06', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', NULL),
(15, 2, 1, '2026-10-06', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', NULL),
(16, 14, 1, '2026-10-08', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(17, 2, 1, '2026-10-08', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(18, 5, 10, '2026-10-09', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', NULL),
(19, 5, 10, '2026-10-13', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', 'Ênfase em mobilidade e alongamento'),
(20, 3, 4, '2026-10-14', '18:00:00', '19:00:00', 'Praça de Esportes Municipal', 'Funcional', 'FALTOU', 'Aluno não compareceu e não avisou'),
(21, 13, 4, '2026-10-14', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'REALIZADA', NULL),
(22, 5, 9, '2026-10-16', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', NULL),
(23, 10, 3, '2026-10-16', '08:00:00', '09:00:00', 'Studio Fit Centro', 'Reabilitação', 'REALIZADA', NULL),
(24, 15, 2, '2026-10-16', '09:00:00', '10:00:00', 'Studio Fit Centro', 'Reabilitação', 'REALIZADA', 'Ajuste de postura nos exercícios de costas'),
(25, 1, 2, '2026-10-19', '08:00:00', '09:00:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(26, 2, 1, '2026-10-20', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', NULL),
(27, 2, 1, '2026-10-22', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', NULL),
(28, 6, 5, '2026-10-26', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'FALTOU', 'Aluno não compareceu e não avisou'),
(29, 6, 5, '2026-10-28', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', 'Foco em técnica de execução'),
(30, 13, 13, '2026-10-28', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'FALTOU', 'Aluno não compareceu e não avisou'),
(31, 14, 1, '2026-11-02', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(32, 1, 2, '2026-11-02', '08:00:00', '09:00:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', 'Foco em técnica de execução'),
(33, 6, 5, '2026-11-02', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(34, 11, 8, '2026-11-02', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(35, 5, 10, '2026-11-03', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', 'Ênfase em mobilidade e alongamento'),
(36, 2, 1, '2026-11-03', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(37, 12, 9, '2026-11-03', '18:00:00', '19:00:00', 'Academia Vitalle', 'Cardio', 'REALIZADA', NULL),
(38, 6, 5, '2026-11-04', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(39, 11, 8, '2026-11-04', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(40, 3, 4, '2026-11-04', '18:00:00', '19:00:00', 'Praça de Esportes Municipal', 'Funcional', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(41, 8, 11, '2026-11-04', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Ênfase em mobilidade e alongamento'),
(42, 13, 13, '2026-11-04', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'REALIZADA', 'Ênfase em mobilidade e alongamento'),
(43, 9, 4, '2026-11-05', '06:00:00', '07:00:00', 'Praça de Esportes Municipal', 'Funcional', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(44, 14, 1, '2026-11-05', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(45, 2, 1, '2026-11-05', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'REALIZADA', NULL),
(46, 12, 9, '2026-11-05', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'REALIZADA', NULL),
(47, 4, 2, '2026-11-05', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Cardio', 'REALIZADA', NULL),
(48, 5, 10, '2026-11-06', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'FALTOU', 'Aluno não compareceu e não avisou'),
(49, 10, 3, '2026-11-06', '08:00:00', '09:00:00', 'Studio Fit Centro', 'Reabilitação', 'REALIZADA', 'Foco em técnica de execução'),
(50, 8, 11, '2026-11-06', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(51, 14, 1, '2026-11-09', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'FALTOU', 'Aluno não compareceu e não avisou'),
(52, 6, 5, '2026-11-09', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(53, 11, 9, '2026-11-09', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'REALIZADA', NULL),
(54, 5, 4, '2026-11-10', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(55, 7, 7, '2026-11-10', '17:00:00', '17:45:00', 'Academia Vitalle', 'Alongamento e mobilidade', 'REALIZADA', NULL),
(56, 12, 9, '2026-11-10', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'FALTOU', 'Aluno não compareceu e não avisou'),
(57, 6, 5, '2026-11-11', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'FALTOU', 'Aluno não compareceu e não avisou'),
(58, 11, 8, '2026-11-11', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Cardio', 'REALIZADA', NULL),
(59, 3, 4, '2026-11-11', '18:00:00', '19:00:00', 'Praça de Esportes Municipal', 'Funcional', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(60, 8, 11, '2026-11-11', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', 'Foco em técnica de execução'),
(61, 13, 4, '2026-11-11', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'FALTOU', 'Aluno não compareceu e não avisou'),
(62, 9, 4, '2026-11-12', '06:00:00', '07:00:00', 'Praça de Esportes Municipal', 'Funcional', 'REALIZADA', 'Foco em técnica de execução'),
(63, 14, 1, '2026-11-12', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'REALIZADA', NULL),
(64, 12, 9, '2026-11-12', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'FALTOU', 'Aluno não compareceu e não avisou'),
(65, 5, 10, '2026-11-13', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'REALIZADA', 'Aluno relatou cansaço; carga reduzida'),
(66, 8, 11, '2026-11-13', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'REALIZADA', NULL),
(67, 14, 1, '2026-11-16', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'AGENDADA', NULL),
(68, 6, 5, '2026-11-16', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(69, 11, 8, '2026-11-16', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(70, 5, 10, '2026-11-17', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'AGENDADA', NULL),
(71, 2, 1, '2026-11-17', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(72, 7, 7, '2026-11-17', '17:00:00', '17:45:00', 'Academia Vitalle', 'Alongamento e mobilidade', 'AGENDADA', NULL),
(73, 12, 9, '2026-11-17', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'AGENDADA', 'Levar toalha e garrafa de água'),
(74, 6, 5, '2026-11-18', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(75, 11, 2, '2026-11-18', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(76, 3, 4, '2026-11-18', '18:00:00', '19:00:00', 'Praça de Esportes Municipal', 'Funcional', 'AGENDADA', NULL),
(77, 13, 13, '2026-11-18', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'AGENDADA', NULL),
(78, 9, 4, '2026-11-19', '06:00:00', '07:00:00', 'Praça de Esportes Municipal', 'Funcional', 'AGENDADA', 'Levar toalha e garrafa de água'),
(79, 14, 1, '2026-11-19', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'AGENDADA', 'Levar toalha e garrafa de água'),
(80, 2, 1, '2026-11-19', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'AGENDADA', NULL),
(81, 12, 9, '2026-11-19', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'AGENDADA', NULL),
(82, 5, 10, '2026-11-20', '07:00:00', '08:00:00', 'Studio Fit Centro', 'Musculação', 'AGENDADA', 'Levar toalha e garrafa de água'),
(83, 10, 3, '2026-11-20', '08:00:00', '09:00:00', 'Studio Fit Centro', 'Reabilitação', 'AGENDADA', 'Levar toalha e garrafa de água'),
(84, 15, 3, '2026-11-20', '09:00:00', '10:00:00', 'Studio Fit Centro', 'Reabilitação', 'AGENDADA', NULL),
(85, 14, 1, '2026-11-23', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'AGENDADA', NULL),
(86, 1, 2, '2026-11-23', '08:00:00', '09:00:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', 'Levar toalha e garrafa de água'),
(87, 6, 5, '2026-11-23', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'CANCELADA', 'Cancelada pelo aluno com antecedência'),
(88, 11, 8, '2026-11-23', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(89, 2, 1, '2026-11-24', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'AGENDADA', 'Levar toalha e garrafa de água'),
(90, 7, 7, '2026-11-24', '17:00:00', '17:45:00', 'Academia Vitalle', 'Alongamento e mobilidade', 'AGENDADA', 'Levar toalha e garrafa de água'),
(91, 12, 9, '2026-11-24', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'AGENDADA', NULL),
(92, 6, 5, '2026-11-25', '09:00:00', '10:30:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(93, 11, 1, '2026-11-25', '10:00:00', '11:00:00', 'Academia Corpo e Mente', 'Musculação', 'AGENDADA', NULL),
(94, 3, 4, '2026-11-25', '18:00:00', '19:00:00', 'Praça de Esportes Municipal', 'Funcional', 'AGENDADA', NULL),
(95, 8, 11, '2026-11-25', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'AGENDADA', NULL),
(96, 13, 13, '2026-11-25', '20:00:00', '21:00:00', 'Praça de Esportes Municipal', 'Funcional', 'AGENDADA', NULL),
(97, 14, 1, '2026-11-26', '07:00:00', '08:00:00', 'Praça de Esportes Municipal', 'Musculação', 'AGENDADA', NULL),
(98, 2, 1, '2026-11-26', '10:00:00', '11:00:00', 'Academia Vitalle', 'Musculação', 'AGENDADA', NULL),
(99, 12, 9, '2026-11-26', '18:00:00', '19:00:00', 'Academia Vitalle', 'Funcional', 'AGENDADA', NULL),
(100, 10, 3, '2026-11-27', '08:00:00', '09:00:00', 'Studio Fit Centro', 'Reabilitação', 'AGENDADA', NULL),
(101, 15, 3, '2026-11-27', '09:00:00', '10:00:00', 'Studio Fit Centro', 'Reabilitação', 'AGENDADA', NULL),
(102, 8, 11, '2026-11-27', '19:00:00', '20:00:00', 'Domicílio do aluno', 'Musculação', 'AGENDADA', NULL);


INSERT INTO AVALIACAO_FISICA (id_avaliacao, id_aluno, id_personal, data_avaliacao, peso_kg, altura_m, percentual_gordura, cintura_cm, observacoes) VALUES
(1, 16, 7, '2025-10-20', 88.0, '1.70', 32.0, 90.2, 'Avaliação inicial'),
(2, 1, 2, '2025-11-11', 78.5, '1.65', 33.0, 85.2, 'Avaliação inicial'),
(3, 17, 8, '2025-12-01', 70.0, '1.63', 31.0, 80.5, 'Avaliação inicial'),
(4, 2, 1, '2025-12-09', 74.0, '1.80', 16.0, 81.1, 'Avaliação inicial'),
(5, 3, 4, '2026-01-19', 68.2, '1.62', 29.0, 79.5, 'Avaliação inicial'),
(6, 16, 7, '2026-01-22', 87.49, '1.70', 31.6, 89.7, 'Reavaliação trimestral'),
(7, 4, 2, '2026-01-27', 96.0, '1.76', 31.0, 95.4, 'Avaliação inicial'),
(8, 18, 11, '2026-02-02', 77.0, '1.79', 18.0, 83.1, 'Avaliação inicial'),
(9, 1, 2, '2026-02-07', 75.56, '1.65', 31.2, 82.5, 'Reavaliação trimestral'),
(10, 5, 10, '2026-02-16', 61.0, '1.70', 24.0, 75.6, 'Avaliação inicial'),
(11, 6, 5, '2026-02-23', 88.0, '1.84', 19.0, 90.2, 'Avaliação inicial'),
(12, 17, 8, '2026-03-02', 67.24, '1.63', 29.4, 78.0, 'Reavaliação trimestral'),
(13, 7, 7, '2026-03-09', 72.0, '1.58', 36.0, 81.6, 'Avaliação inicial'),
(14, 2, 1, '2026-03-13', 75.05, '1.80', 15.6, 82.0, 'Reavaliação trimestral'),
(15, 8, 11, '2026-03-16', 70.0, '1.78', 14.0, 78.5, 'Avaliação inicial'),
(16, 9, 4, '2026-03-30', 64.0, '1.67', 27.0, 77.2, 'Avaliação inicial'),
(17, 10, 3, '2026-04-13', 83.0, '1.72', 29.0, 87.0, 'Avaliação inicial'),
(18, 3, 4, '2026-04-17', 67.64, '1.62', 28.4, 79.0, 'Reavaliação trimestral'),
(19, 11, 8, '2026-04-20', 81.0, '1.64', 38.0, 86.6, 'Avaliação inicial'),
(20, 16, 7, '2026-04-21', 87.24, '1.70', 31.2, 89.5, 'Reavaliação trimestral'),
(21, 4, 2, '2026-04-28', 93.09, '1.76', 29.4, 92.8, 'Reavaliação trimestral'),
(22, 18, 11, '2026-04-28', 78.1, '1.79', 17.7, 84.0, 'Reavaliação trimestral'),
(23, 1, 2, '2026-05-03', 73.05, '1.65', 29.6, 80.3, 'Reavaliação trimestral'),
(24, 12, 9, '2026-05-11', 92.0, '1.81', 22.0, 92.8, 'Avaliação inicial'),
(25, 5, 10, '2026-05-16', 62.0, '1.70', 23.9, 76.4, 'Reavaliação trimestral'),
(26, 6, 5, '2026-05-19', 89.36, '1.84', 18.4, 91.4, 'Reavaliação trimestral'),
(27, 13, 13, '2026-05-25', 58.0, '1.69', 23.0, 73.9, 'Avaliação inicial'),
(28, 17, 8, '2026-05-27', 64.49, '1.63', 27.5, 75.5, 'Reavaliação trimestral'),
(29, 14, 1, '2026-06-08', 85.0, '1.75', 25.0, 88.2, 'Avaliação inicial'),
(30, 7, 7, '2026-06-11', 71.11, '1.58', 35.2, 80.8, 'Reavaliação trimestral'),
(31, 8, 11, '2026-06-15', 70.78, '1.78', 13.4, 79.2, 'Reavaliação trimestral'),
(32, 2, 1, '2026-06-16', 75.7, '1.80', 15.1, 82.6, 'Reavaliação trimestral'),
(33, 9, 4, '2026-07-05', 63.52, '1.67', 26.2, 76.8, 'Reavaliação trimestral'),
(34, 10, 3, '2026-07-10', 82.42, '1.72', 28.3, 86.4, 'Reavaliação trimestral'),
(35, 3, 4, '2026-07-21', 67.0, '1.62', 27.5, 78.4, 'Reavaliação trimestral'),
(36, 11, 8, '2026-07-21', 78.58, '1.64', 36.3, 84.4, 'Reavaliação trimestral'),
(37, 16, 7, '2026-07-26', 86.5, '1.70', 30.6, 88.8, 'Reavaliação trimestral'),
(38, 1, 2, '2026-07-27', 70.08, '1.65', 27.7, 77.6, 'Reavaliação trimestral'),
(39, 4, 2, '2026-08-01', 89.79, '1.76', 27.7, 89.8, 'Reavaliação trimestral'),
(40, 18, 11, '2026-08-02', 78.63, '1.79', 17.6, 84.5, 'Reavaliação trimestral'),
(41, 12, 9, '2026-08-08', 88.99, '1.81', 20.3, 90.1, 'Reavaliação trimestral'),
(42, 6, 5, '2026-08-17', 90.51, '1.84', 18.1, 92.5, 'Reavaliação trimestral'),
(43, 15, 3, '2026-08-17', 66.0, '1.66', 28.0, 78.3, 'Avaliação inicial'),
(44, 5, 10, '2026-08-19', 62.46, '1.70', 23.4, 76.9, 'Reavaliação trimestral'),
(45, 13, 13, '2026-08-29', 57.69, '1.69', 22.2, 73.6, 'Reavaliação trimestral'),
(46, 14, 1, '2026-09-01', 86.21, '1.75', 24.4, 89.3, 'Reavaliação trimestral'),
(47, 7, 7, '2026-09-10', 70.37, '1.58', 34.5, 80.1, 'Reavaliação trimestral'),
(48, 8, 11, '2026-09-17', 71.93, '1.78', 13.2, 80.2, 'Reavaliação trimestral'),
(49, 2, 1, '2026-09-19', 76.68, '1.80', 14.7, 83.5, 'Reavaliação trimestral'),
(50, 9, 4, '2026-10-09', 62.74, '1.67', 25.5, 76.1, 'Reavaliação trimestral'),
(51, 10, 3, '2026-10-10', 82.24, '1.72', 27.6, 86.3, 'Reavaliação trimestral'),
(52, 11, 8, '2026-10-18', 76.16, '1.64', 34.2, 82.2, 'Reavaliação trimestral'),
(53, 3, 4, '2026-10-22', 66.35, '1.62', 26.9, 77.8, 'Reavaliação trimestral'),
(54, 1, 2, '2026-10-24', 67.74, '1.65', 25.8, 75.5, 'Reavaliação trimestral'),
(55, 4, 2, '2026-11-04', 86.75, '1.76', 25.9, 87.1, 'Reavaliação trimestral'),
(56, 12, 9, '2026-11-06', 86.24, '1.81', 18.6, 87.6, 'Reavaliação trimestral'),
(57, 15, 3, '2026-11-13', 65.92, '1.66', 27.7, 78.2, 'Reavaliação trimestral');


INSERT INTO PAGAMENTO (id_pagamento, id_aluno, referencia_mes, valor, data_vencimento, data_pagamento, forma_pagamento, status) VALUES
(1, 17, '2026-04', '380.00', '2026-04-05', '2026-04-08', 'CARTAO_CREDITO', 'PAGO'),
(2, 17, '2026-05', '380.00', '2026-05-05', '2026-05-04', 'TRANSFERENCIA', 'PAGO'),
(3, 17, '2026-06', '380.00', '2026-06-05', '2026-06-04', 'PIX', 'PAGO'),
(4, 16, '2026-06', '280.00', '2026-06-10', '2026-06-08', 'PIX', 'PAGO'),
(5, 16, '2026-07', '280.00', '2026-07-10', '2026-07-14', 'PIX', 'PAGO'),
(6, 18, '2026-07', '480.00', '2026-07-10', '2026-07-09', 'PIX', 'PAGO'),
(7, 16, '2026-08', '280.00', '2026-08-10', NULL, NULL, 'ATRASADO'),
(8, 18, '2026-08', '480.00', '2026-08-10', '2026-08-09', 'PIX', 'PAGO'),
(9, 1, '2026-09', '380.00', '2026-09-05', '2026-09-09', 'PIX', 'PAGO'),
(10, 7, '2026-09', '280.00', '2026-09-05', '2026-09-09', 'PIX', 'PAGO'),
(11, 9, '2026-09', '380.00', '2026-09-05', '2026-09-03', 'PIX', 'PAGO'),
(12, 11, '2026-09', '480.00', '2026-09-05', '2026-09-05', 'PIX', 'PAGO'),
(13, 2, '2026-09', '560.00', '2026-09-10', '2026-09-09', 'CARTAO_DEBITO', 'PAGO'),
(14, 4, '2026-09', '380.00', '2026-09-10', '2026-09-08', 'PIX', 'PAGO'),
(15, 6, '2026-09', '480.00', '2026-09-10', '2026-09-07', 'PIX', 'PAGO'),
(16, 12, '2026-09', '480.00', '2026-09-10', '2026-09-12', 'DINHEIRO', 'PAGO'),
(17, 14, '2026-09', '480.00', '2026-09-10', '2026-09-14', 'PIX', 'PAGO'),
(18, 18, '2026-09', '480.00', '2026-09-10', NULL, NULL, 'ATRASADO'),
(19, 3, '2026-09', '380.00', '2026-09-20', '2026-09-24', 'CARTAO_CREDITO', 'PAGO'),
(20, 5, '2026-09', '480.00', '2026-09-20', '2026-09-20', 'PIX', 'PAGO'),
(21, 8, '2026-09', '480.00', '2026-09-20', '2026-09-17', 'PIX', 'PAGO'),
(22, 10, '2026-09', '380.00', '2026-09-20', '2026-09-19', 'TRANSFERENCIA', 'PAGO'),
(23, 13, '2026-09', '380.00', '2026-09-20', '2026-09-18', 'PIX', 'PAGO'),
(24, 15, '2026-09', '280.00', '2026-09-20', '2026-09-24', 'CARTAO_CREDITO', 'PAGO'),
(25, 1, '2026-10', '380.00', '2026-10-05', '2026-10-03', 'CARTAO_CREDITO', 'PAGO'),
(26, 7, '2026-10', '280.00', '2026-10-05', '2026-10-07', 'PIX', 'PAGO'),
(27, 9, '2026-10', '380.00', '2026-10-05', '2026-10-09', 'CARTAO_DEBITO', 'PAGO'),
(28, 11, '2026-10', '480.00', '2026-10-05', '2026-10-04', 'CARTAO_DEBITO', 'PAGO'),
(29, 2, '2026-10', '560.00', '2026-10-10', '2026-10-10', 'PIX', 'PAGO'),
(30, 4, '2026-10', '380.00', '2026-10-10', '2026-10-10', 'CARTAO_CREDITO', 'PAGO'),
(31, 6, '2026-10', '480.00', '2026-10-10', '2026-10-10', 'CARTAO_CREDITO', 'PAGO'),
(32, 12, '2026-10', '480.00', '2026-10-10', '2026-10-09', 'TRANSFERENCIA', 'PAGO'),
(33, 14, '2026-10', '480.00', '2026-10-10', '2026-10-12', 'PIX', 'PAGO'),
(34, 3, '2026-10', '380.00', '2026-10-20', '2026-10-18', 'CARTAO_CREDITO', 'PAGO'),
(35, 5, '2026-10', '480.00', '2026-10-20', '2026-10-21', 'PIX', 'PAGO'),
(36, 8, '2026-10', '480.00', '2026-10-20', NULL, NULL, 'ATRASADO'),
(37, 10, '2026-10', '380.00', '2026-10-20', '2026-10-19', 'PIX', 'PAGO'),
(38, 13, '2026-10', '380.00', '2026-10-20', NULL, NULL, 'ATRASADO'),
(39, 15, '2026-10', '280.00', '2026-10-20', '2026-10-19', 'PIX', 'PAGO'),
(40, 1, '2026-11', '380.00', '2026-11-05', NULL, NULL, 'ATRASADO'),
(41, 7, '2026-11', '280.00', '2026-11-05', NULL, NULL, 'ATRASADO'),
(42, 9, '2026-11', '380.00', '2026-11-05', '2026-11-07', 'CARTAO_DEBITO', 'PAGO'),
(43, 11, '2026-11', '480.00', '2026-11-05', '2026-11-03', 'CARTAO_DEBITO', 'PAGO'),
(44, 2, '2026-11', '560.00', '2026-11-10', '2026-11-07', 'PIX', 'PAGO'),
(45, 4, '2026-11', '380.00', '2026-11-10', '2026-11-07', 'PIX', 'PAGO'),
(46, 6, '2026-11', '480.00', '2026-11-10', NULL, NULL, 'ATRASADO'),
(47, 12, '2026-11', '480.00', '2026-11-10', NULL, NULL, 'ATRASADO'),
(48, 14, '2026-11', '480.00', '2026-11-10', '2026-11-10', 'PIX', 'PAGO'),
(49, 3, '2026-11', '380.00', '2026-11-20', NULL, NULL, 'PENDENTE'),
(50, 5, '2026-11', '480.00', '2026-11-20', NULL, NULL, 'PENDENTE'),
(51, 8, '2026-11', '480.00', '2026-11-20', '2026-11-15', 'PIX', 'PAGO'),
(52, 10, '2026-11', '380.00', '2026-11-20', NULL, NULL, 'PENDENTE'),
(53, 13, '2026-11', '380.00', '2026-11-20', NULL, NULL, 'PENDENTE'),
(54, 15, '2026-11', '280.00', '2026-11-20', NULL, NULL, 'PENDENTE');


INSERT INTO REGISTRO_TREINO (id_registro, id_aluno, id_exercicio, data_execucao, series_realizadas, repeticoes_realizadas, carga_kg, observacoes) VALUES
(1, 17, 15, '2026-06-02', 3, 15, '25.0', NULL),
(2, 17, 3, '2026-06-02', 3, 12, '10.5', 'Concluiu todas as séries com facilidade'),
(3, 17, 4, '2026-06-09', 3, 11, '15.0', 'Aumentou a carga em relação ao treino anterior'),
(4, 17, 16, '2026-06-09', 3, 13, '13.0', NULL),
(5, 17, 23, '2026-06-16', 3, 20, '0.0', NULL),
(6, 17, 29, '2026-06-16', 6, 1, '0.0', 'Aumentou a carga em relação ao treino anterior'),
(7, 17, 15, '2026-06-23', 3, 13, '26.5', 'Execução com boa técnica'),
(8, 17, 3, '2026-06-23', 3, 10, '11.0', NULL),
(9, 16, 15, '2026-08-03', 3, 12, '28.0', NULL),
(10, 16, 4, '2026-08-03', 3, 12, '17.5', NULL),
(11, 16, 16, '2026-08-10', 3, 12, '14.5', NULL),
(12, 16, 8, '2026-08-10', 3, 10, '2.0', 'Aumentou a carga em relação ao treino anterior'),
(13, 16, 22, '2026-08-17', 3, 15, '14.5', 'Concluiu todas as séries com facilidade'),
(14, 16, 23, '2026-08-17', 3, 12, '0.0', 'Reduziu a carga por desconforto'),
(15, 18, 1, '2026-09-02', 4, 9, '50.0', 'Reduziu a carga por desconforto'),
(16, 18, 2, '2026-09-02', 4, 9, '20.0', NULL),
(17, 18, 7, '2026-09-09', 3, 10, '14.5', NULL),
(18, 18, 8, '2026-09-09', 3, 13, '8.0', 'Concluiu todas as séries com facilidade'),
(19, 18, 11, '2026-09-16', 3, 10, '26.0', NULL),
(20, 18, 12, '2026-09-16', 3, 10, '21.0', 'Reduziu a carga por desconforto'),
(21, 18, 1, '2026-09-23', 4, 9, '53.0', NULL),
(22, 18, 2, '2026-09-23', 4, 8, '21.0', 'Aumentou a carga em relação ao treino anterior'),
(23, 2, 1, '2026-10-06', 4, 8, '50.0', 'Execução com boa técnica'),
(24, 2, 2, '2026-10-06', 4, 10, '20.0', 'Execução com boa técnica'),
(25, 5, 19, '2026-10-06', 4, 10, '30.0', 'Reduziu a carga por desconforto'),
(26, 5, 20, '2026-10-06', 4, 12, '9.5', NULL),
(27, 5, 27, '2026-10-09', 3, 15, '24.5', NULL),
(28, 5, 17, '2026-10-09', 3, 11, '18.5', 'Aumentou a carga em relação ao treino anterior'),
(29, 5, 18, '2026-10-13', 3, 11, '18.5', 'Aumentou a carga em relação ao treino anterior'),
(30, 5, 24, '2026-10-13', 3, 1, '0.0', 'Aumentou a carga em relação ao treino anterior'),
(31, 13, 29, '2026-10-14', 6, 1, '0.0', 'Reduziu a carga por desconforto'),
(32, 13, 31, '2026-10-14', 4, 15, '7.0', 'Concluiu todas as séries com facilidade'),
(33, 5, 19, '2026-10-16', 4, 10, '32.0', NULL),
(34, 5, 20, '2026-10-16', 4, 10, '10.0', NULL),
(35, 10, 25, '2026-10-16', 3, 10, '0.0', NULL),
(36, 10, 24, '2026-10-16', 3, 1, '0.0', 'Concluiu todas as séries com facilidade'),
(37, 15, 25, '2026-10-16', 3, 11, '0.0', 'Concluiu todas as séries com facilidade'),
(38, 15, 24, '2026-10-16', 3, 1, '0.0', 'Reduziu a carga por desconforto'),
(39, 1, 14, '2026-10-19', 3, 14, '17.0', NULL),
(40, 1, 2, '2026-10-19', 3, 11, '7.5', NULL),
(41, 2, 4, '2026-10-20', 4, 9, '50.0', 'Aumentou a carga em relação ao treino anterior'),
(42, 2, 5, '2026-10-20', 4, 10, '40.0', 'Concluiu todas as séries com facilidade'),
(43, 2, 7, '2026-10-22', 3, 10, '14.5', NULL),
(44, 2, 8, '2026-10-22', 3, 15, '8.0', 'Aumentou a carga em relação ao treino anterior'),
(45, 6, 14, '2026-10-28', 5, 3, '125.0', 'Aumentou a carga em relação ao treino anterior'),
(46, 6, 1, '2026-10-28', 5, 4, '100.0', 'Concluiu todas as séries com facilidade'),
(47, 1, 6, '2026-11-02', 3, 10, '17.5', NULL),
(48, 1, 31, '2026-11-02', 4, 15, '6.5', NULL),
(49, 6, 18, '2026-11-02', 4, 6, '115.0', 'Execução com boa técnica'),
(50, 6, 5, '2026-11-02', 4, 6, '89.0', NULL),
(51, 11, 15, '2026-11-02', 3, 15, '25.0', 'Concluiu todas as séries com facilidade'),
(52, 11, 3, '2026-11-02', 3, 10, '10.5', NULL),
(53, 2, 6, '2026-11-03', 3, 12, '46.0', NULL),
(54, 2, 9, '2026-11-03', 3, 8, '25.5', 'Aumentou a carga em relação ao treino anterior'),
(55, 5, 27, '2026-11-03', 3, 15, '26.0', NULL),
(56, 5, 17, '2026-11-03', 3, 11, '19.5', NULL),
(57, 12, 14, '2026-11-03', 3, 15, '40.0', NULL),
(58, 12, 2, '2026-11-03', 3, 11, '18.0', 'Concluiu todas as séries com facilidade'),
(59, 3, 29, '2026-11-04', 6, 1, '0.0', 'Reduziu a carga por desconforto'),
(60, 3, 31, '2026-11-04', 4, 15, '5.0', NULL),
(61, 6, 7, '2026-11-04', 4, 8, '31.0', NULL),
(62, 6, 24, '2026-11-04', 3, 1, '0.0', 'Execução com boa técnica'),
(63, 8, 1, '2026-11-04', 4, 10, '35.0', 'Reduziu a carga por desconforto'),
(64, 8, 2, '2026-11-04', 4, 10, '14.0', NULL),
(65, 11, 4, '2026-11-04', 3, 12, '15.0', 'Concluiu todas as séries com facilidade'),
(66, 11, 16, '2026-11-04', 3, 13, '13.0', 'Aumentou a carga em relação ao treino anterior'),
(67, 13, 30, '2026-11-04', 4, 1, '0.0', 'Reduziu a carga por desconforto'),
(68, 13, 20, '2026-11-04', 3, 15, '7.0', NULL),
(69, 2, 11, '2026-11-05', 3, 10, '26.0', 'Reduziu a carga por desconforto'),
(70, 2, 12, '2026-11-05', 3, 10, '21.0', NULL),
(71, 12, 6, '2026-11-05', 3, 12, '41.0', 'Concluiu todas as séries com facilidade'),
(72, 12, 31, '2026-11-05', 4, 14, '16.5', 'Execução com boa técnica'),
(73, 14, 1, '2026-11-05', 4, 8, '50.0', 'Execução com boa técnica'),
(74, 14, 2, '2026-11-05', 4, 10, '20.0', NULL),
(75, 8, 14, '2026-11-06', 4, 10, '42.0', NULL),
(76, 8, 15, '2026-11-06', 4, 10, '84.0', 'Execução com boa técnica'),
(77, 10, 15, '2026-11-06', 3, 13, '14.5', 'Aumentou a carga em relação ao treino anterior'),
(78, 10, 28, '2026-11-06', 3, 13, '9.0', 'Reduziu a carga por desconforto'),
(79, 6, 14, '2026-11-09', 5, 5, '132.5', NULL),
(80, 6, 1, '2026-11-09', 5, 5, '106.0', 'Execução com boa técnica'),
(81, 11, 23, '2026-11-09', 3, 18, '0.0', 'Reduziu a carga por desconforto'),
(82, 11, 29, '2026-11-09', 6, 1, '0.0', 'Reduziu a carga por desconforto'),
(83, 5, 18, '2026-11-10', 3, 12, '20.0', 'Concluiu todas as séries com facilidade'),
(84, 5, 24, '2026-11-10', 3, 1, '0.0', NULL),
(85, 7, 15, '2026-11-10', 3, 12, '17.0', NULL),
(86, 7, 4, '2026-11-10', 3, 10, '10.5', NULL),
(87, 3, 30, '2026-11-11', 4, 1, '0.0', 'Aumentou a carga em relação ao treino anterior'),
(88, 3, 20, '2026-11-11', 3, 14, '5.0', NULL),
(89, 8, 7, '2026-11-11', 3, 12, '10.0', NULL),
(90, 8, 8, '2026-11-11', 3, 14, '5.5', NULL),
(91, 11, 15, '2026-11-11', 3, 14, '26.5', NULL),
(92, 11, 3, '2026-11-11', 3, 12, '11.0', NULL),
(93, 9, 29, '2026-11-12', 6, 1, '0.0', NULL),
(94, 9, 31, '2026-11-12', 4, 13, '7.0', 'Reduziu a carga por desconforto'),
(95, 14, 7, '2026-11-12', 3, 11, '14.5', 'Reduziu a carga por desconforto'),
(96, 14, 8, '2026-11-12', 3, 14, '8.0', NULL),
(97, 5, 19, '2026-11-13', 4, 11, '33.5', 'Execução com boa técnica'),
(98, 5, 20, '2026-11-13', 4, 10, '10.5', 'Reduziu a carga por desconforto'),
(99, 8, 16, '2026-11-13', 3, 10, '28.5', NULL),
(100, 8, 17, '2026-11-13', 3, 11, '25.0', NULL);


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


USE personal_trainer_db;


-- ---------------------------------------------------------------------
SELECT id_aluno,
       nome,
       email,
       telefone,
       data_cadastro
FROM ALUNO
WHERE status = 'ATIVO'
ORDER BY nome;


SELECT id_aluno,
       objetivo,
       nivel_experiencia,
       frequencia_semanal_desejada
FROM PERFIL_ALUNO
WHERE objetivo IN ('HIPERTROFIA', 'FORCA')
  AND frequencia_semanal_desejada BETWEEN 4 AND 5
ORDER BY frequencia_semanal_desejada DESC, id_aluno;


SELECT DISTINCT data_aula,
                local
FROM AULA
WHERE status = 'AGENDADA'
  AND data_aula BETWEEN '2026-11-16' AND '2026-11-22'
ORDER BY data_aula, local;


SELECT id_exercicio,
       nome,
       equipamento,
       nivel_dificuldade
FROM EXERCICIO
WHERE id_grupo IN (7, 8, 9)
  AND equipamento LIKE '%Barra%'
ORDER BY id_grupo, nome
LIMIT 5;


SELECT id_pagamento,
       id_aluno,
       referencia_mes,
       valor,
       data_vencimento,
       status
FROM PAGAMENTO
WHERE status IN ('PENDENTE', 'ATRASADO')
ORDER BY data_vencimento, id_aluno;


SELECT a.nome        AS aluno,
       pl.nome       AS plano,
       pt.nome       AS personal_responsavel,
       pl.data_inicio,
       pl.status
FROM ALUNO a
INNER JOIN PLANO_TREINO pl     ON pl.id_aluno = a.id_aluno
INNER JOIN PERSONAL_TRAINER pt ON pt.id_personal = pl.id_personal
ORDER BY a.nome, pl.data_inicio;


SELECT pl.id_plano,
       a.nome                AS aluno,
       pl.nome               AS plano,
       COUNT(*)              AS qtd_exercicios,
       SUM(ip.series)        AS total_series,
       GROUP_CONCAT(e.nome ORDER BY ip.ordem SEPARATOR ', ') AS exercicios
FROM PLANO_TREINO pl
INNER JOIN ALUNO a       ON a.id_aluno = pl.id_aluno
INNER JOIN ITEM_PLANO ip ON ip.id_plano = pl.id_plano
INNER JOIN EXERCICIO e   ON e.id_exercicio = ip.id_exercicio
GROUP BY pl.id_plano, a.nome, pl.nome
ORDER BY pl.id_plano;


SELECT a.nome                AS aluno,
       COUNT(*)              AS aulas_realizadas,
       MAX(au.data_aula)     AS ultima_aula
FROM ALUNO a
INNER JOIN AULA au ON au.id_aluno = a.id_aluno
WHERE au.status = 'REALIZADA'
GROUP BY a.id_aluno, a.nome
HAVING COUNT(*) >= 3
ORDER BY aulas_realizadas DESC, aluno;


SELECT e.nome                        AS exercicio,
       g.nome                        AS grupo_muscular,
       COUNT(*)                      AS qtd_planos,
       ROUND(AVG(ip.series), 1)      AS media_series,
       MAX(ip.carga_sugerida_kg)     AS maior_carga_sugerida_kg
FROM EXERCICIO e
INNER JOIN GRUPO_MUSCULAR g ON g.id_grupo = e.id_grupo
INNER JOIN ITEM_PLANO ip    ON ip.id_exercicio = e.id_exercicio
GROUP BY e.id_exercicio, e.nome, g.nome
HAVING COUNT(*) >= 4
ORDER BY qtd_planos DESC, exercicio
LIMIT 10;


SELECT a.nome                           AS aluno,
       COUNT(*)                         AS avaliacoes,
       ROUND(AVG(v.peso_kg), 1)         AS peso_medio_kg,
       MIN(v.peso_kg)                   AS menor_peso_kg,
       MAX(v.peso_kg)                   AS maior_peso_kg,
       MAX(v.peso_kg) - MIN(v.peso_kg)  AS variacao_kg
FROM ALUNO a
INNER JOIN AVALIACAO_FISICA v ON v.id_aluno = a.id_aluno
GROUP BY a.id_aluno, a.nome
HAVING COUNT(*) >= 2
ORDER BY peso_medio_kg DESC;


SELECT a.nome            AS aluno,
       v.data_avaliacao  AS ultima_avaliacao,
       v.peso_kg
FROM AVALIACAO_FISICA v
INNER JOIN ALUNO a ON a.id_aluno = v.id_aluno
WHERE v.peso_kg > (SELECT AVG(peso_kg) FROM AVALIACAO_FISICA)
  AND v.data_avaliacao = (SELECT MAX(v2.data_avaliacao)
                          FROM AVALIACAO_FISICA v2
                          WHERE v2.id_aluno = v.id_aluno)
ORDER BY v.peso_kg DESC;


SELECT pt.nome                                          AS personal,
       pt.status,
       COUNT(au.id_aula)                                AS total_aulas,
       COALESCE(SUM(au.status = 'REALIZADA'), 0)        AS realizadas,
       COALESCE(SUM(au.status = 'AGENDADA'), 0)         AS agendadas
FROM PERSONAL_TRAINER pt
LEFT JOIN AULA au ON au.id_personal = pt.id_personal
GROUP BY pt.id_personal, pt.nome, pt.status
ORDER BY total_aulas DESC, personal;


SELECT referencia_mes,
       COUNT(*)                                                      AS mensalidades,
       SUM(valor)                                                    AS faturado,
       SUM(CASE WHEN status = 'PAGO' THEN valor ELSE 0 END)          AS recebido,
       SUM(CASE WHEN status <> 'PAGO' THEN valor ELSE 0 END)         AS em_aberto,
       ROUND(100 * SUM(CASE WHEN status = 'ATRASADO' THEN valor ELSE 0 END)
                 / SUM(valor), 1)                                    AS inadimplencia_pct,
       ROUND(AVG(valor), 2)                                          AS ticket_medio
FROM PAGAMENTO
WHERE referencia_mes BETWEEN '2026-09' AND '2026-11'
GROUP BY referencia_mes
ORDER BY referencia_mes;


SELECT
    (SELECT COUNT(*) FROM ALUNO WHERE status = 'ATIVO')              AS alunos_ativos,
    (SELECT COUNT(*) FROM PERSONAL_TRAINER WHERE status = 'ATIVO')   AS personais_ativos,
    (SELECT COUNT(*) FROM AULA WHERE status = 'REALIZADA')           AS aulas_realizadas,
    (SELECT ROUND(100 * SUM(status = 'REALIZADA') / COUNT(*), 1)
       FROM AULA WHERE status IN ('REALIZADA', 'FALTOU'))            AS comparecimento_pct,
    (SELECT ROUND(AVG(valor), 2) FROM PAGAMENTO)                     AS mensalidade_media,
    (SELECT SUM(valor) FROM PAGAMENTO WHERE status = 'PAGO')         AS total_recebido,
    (SELECT SUM(valor) FROM PAGAMENTO WHERE status <> 'PAGO')        AS total_em_aberto,
    (SELECT ROUND(AVG(peso_kg), 1) FROM AVALIACAO_FISICA)            AS peso_medio_kg;