SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION";
SET time_zone = "-03:00"; -- Definindo para o fuso horário do Brasil (Brasília)

-- Criação do banco de dados com charset otimizado para caracteres globais
CREATE DATABASE IF NOT EXISTS `viagens_pro` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `viagens_pro`;

-- --------------------------------------------------------

-- Tabela de Categorias para os Destinos (Ex: Praia, Montanha, Cidade Histórica)
CREATE TABLE `categorias` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `descricao` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_nome_categoria_unico` (`nome`)
) ENGINE=InnoDB COMMENT='Categorias para classificar os destinos.';

-- --------------------------------------------------------

-- Tabela `destinos`
CREATE TABLE `destinos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_categoria` INT UNSIGNED NOT NULL,
  `nome` VARCHAR(255) NOT NULL,
  `descricao` TEXT NOT NULL,
  `localizacao_cidade` VARCHAR(100) NOT NULL,
  `localizacao_estado` VARCHAR(50) NOT NULL,
  `localizacao_pais` VARCHAR(50) NOT NULL,
  `preco_base_diaria` DECIMAL(10, 2) NOT NULL COMMENT 'Preço base por dia/pessoa',
  `capacidade_maxima` INT UNSIGNED DEFAULT NULL COMMENT 'Capacidade de pessoas do local/pacote',
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Indica se o destino está disponível para reserva',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_nome_destino_unico` (`nome`),
  KEY `idx_id_categoria` (`id_categoria`),
  CONSTRAINT `fk_destinos_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Armazena informações detalhadas sobre os destinos turísticos.';

-- --------------------------------------------------------

-- Tabela para galeria de fotos dos destinos
CREATE TABLE `galeria_fotos_destinos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_destino` INT UNSIGNED NOT NULL,
  `url_imagem` VARCHAR(2048) NOT NULL,
  `descricao_alt` VARCHAR(255) DEFAULT NULL COMMENT 'Texto alternativo para acessibilidade',
  `ordem` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_id_destino_fotos` (`id_destino`),
  CONSTRAINT `fk_fotos_destino` FOREIGN KEY (`id_destino`) REFERENCES `destinos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Galeria de imagens para cada destino.';

-- --------------------------------------------------------

-- Tabela `usuarios`
CREATE TABLE `usuarios` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `senha_hash` VARCHAR(255) NOT NULL COMMENT 'Hash da senha (NUNCA armazene senhas em texto puro)',
  `data_nascimento` DATE NOT NULL,
  `data_cadastro` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ultimo_login` TIMESTAMP NULL DEFAULT NULL,
  `status` ENUM('ativo', 'inativo', 'pendente_verificacao') NOT NULL DEFAULT 'pendente_verificacao',
  `tipo` ENUM('cliente', 'admin') NOT NULL DEFAULT 'cliente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_email_unico` (`email`)
) ENGINE=InnoDB COMMENT='Gerencia os usuários da plataforma, incluindo segurança e status.';

-- --------------------------------------------------------

-- Tabela `enderecos` normalizada
CREATE TABLE `enderecos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_usuario` INT UNSIGNED NOT NULL,
  `logradouro` VARCHAR(255) NOT NULL,
  `numero` VARCHAR(20) NOT NULL,
  `complemento` VARCHAR(100) DEFAULT NULL,
  `bairro` VARCHAR(100) NOT NULL,
  `cidade` VARCHAR(100) NOT NULL,
  `estado` VARCHAR(50) NOT NULL,
  `cep` VARCHAR(10) NOT NULL,
  `pais` VARCHAR(50) NOT NULL DEFAULT 'Brasil',
  `tipo_endereco` ENUM('principal', 'cobranca', 'outro') NOT NULL DEFAULT 'principal',
  PRIMARY KEY (`id`),
  KEY `idx_id_usuario_enderecos` (`id_usuario`),
  CONSTRAINT `fk_enderecos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Armazena endereços dos usuários de forma normalizada.';

-- --------------------------------------------------------

-- Tabela `reservas`
CREATE TABLE `reservas` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo_reserva` VARCHAR(20) NOT NULL COMMENT 'Código único e amigável para o cliente',
  `id_usuario` INT UNSIGNED NOT NULL,
  `id_destino` INT UNSIGNED NOT NULL,
  `data_check_in` DATE NOT NULL,
  `data_check_out` DATE NOT NULL,
  `numero_adultos` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `numero_criancas` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `valor_total` DECIMAL(10, 2) NOT NULL,
  `status` ENUM('pendente', 'confirmada', 'cancelada', 'finalizada') NOT NULL DEFAULT 'pendente',
  `data_criacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_atualizacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_codigo_reserva_unico` (`codigo_reserva`),
  KEY `idx_id_usuario_reservas` (`id_usuario`),
  KEY `idx_id_destino_reservas` (`id_destino`),
  CONSTRAINT `fk_reservas_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reservas_destino` FOREIGN KEY (`id_destino`) REFERENCES `destinos` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_datas_reserva` CHECK (`data_check_out` > `data_check_in`)
) ENGINE=InnoDB COMMENT='Controla as reservas de viagens, com detalhes de datas e valores.';

-- --------------------------------------------------------

-- Tabela `pagamentos`
CREATE TABLE `pagamentos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_reserva` INT UNSIGNED NOT NULL,
  `valor` DECIMAL(10, 2) NOT NULL,
  `metodo_pagamento` ENUM('cartao_credito', 'pix', 'boleto') NOT NULL,
  `status` ENUM('pendente', 'aprovado', 'recusado', 'reembolsado') NOT NULL DEFAULT 'pendente',
  `id_transacao_gateway` VARCHAR(255) DEFAULT NULL COMMENT 'ID da transação no gateway de pagamento (Stripe, etc)',
  `data_pagamento` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_id_reserva_pagamentos` (`id_reserva`),
  CONSTRAINT `fk_pagamentos_reserva` FOREIGN KEY (`id_reserva`) REFERENCES `reservas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Registra os pagamentos associados a cada reserva.';

-- --------------------------------------------------------

-- Tabela `avaliacoes`
CREATE TABLE `avaliacoes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_reserva` INT UNSIGNED NOT NULL,
  `id_usuario` INT UNSIGNED NOT NULL,
  `id_destino` INT UNSIGNED NOT NULL,
  `pontuacao` TINYINT UNSIGNED NOT NULL COMMENT 'Nota de 1 a 5',
  `comentario` TEXT DEFAULT NULL,
  `data_avaliacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_avaliacao_unica_por_reserva` (`id_reserva`),
  KEY `idx_id_usuario_avaliacoes` (`id_usuario`),
  KEY `idx_id_destino_avaliacoes` (`id_destino`),
  CONSTRAINT `fk_avaliacoes_reserva` FOREIGN KEY (`id_reserva`) REFERENCES `reservas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_avaliacoes_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_avaliacoes_destino` FOREIGN KEY (`id_destino`) REFERENCES `destinos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_pontuacao_valida` CHECK (`pontuacao` >= 1 AND `pontuacao` <= 5)
) ENGINE=InnoDB COMMENT='Permite que usuários avaliem os destinos após a viagem.';