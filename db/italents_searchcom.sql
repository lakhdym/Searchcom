-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : mar. 10 mars 2026 à 11:50
-- Version du serveur : 10.6.24-MariaDB-cll-lve
-- Version de PHP : 8.4.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `italents_searchcom`
--

-- --------------------------------------------------------

--
-- Structure de la table `app_settings`
--

CREATE TABLE `app_settings` (
  `id` bigint(20) NOT NULL,
  `currency` varchar(10) NOT NULL DEFAULT 'MAD',
  `publish_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `boost_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `updated_by` bigint(20) DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `app_settings`
--

INSERT INTO `app_settings` (`id`, `currency`, `publish_price`, `boost_price`, `updated_by`, `updated_at`) VALUES
(1, 'MAD', 10.00, 5.00, NULL, '2026-03-03 11:19:19');

-- --------------------------------------------------------

--
-- Structure de la table `boost_plans`
--

CREATE TABLE `boost_plans` (
  `id` bigint(20) NOT NULL,
  `code` enum('24h','3d','7d') NOT NULL,
  `duration_hours` int(11) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `boost_plans`
--

INSERT INTO `boost_plans` (`id`, `code`, `duration_hours`, `is_active`, `created_at`) VALUES
(1, '24h', 24, 1, '2026-03-03 11:19:19'),
(2, '3d', 72, 1, '2026-03-03 11:19:19'),
(3, '7d', 168, 1, '2026-03-03 11:19:19');

-- --------------------------------------------------------

--
-- Structure de la table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) NOT NULL,
  `slug` varchar(80) NOT NULL,
  `name_fr` varchar(120) NOT NULL,
  `name_en` varchar(120) NOT NULL,
  `name_ar` varchar(120) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `conversations`
--

CREATE TABLE `conversations` (
  `id` bigint(20) NOT NULL,
  `listing_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `conversation_participants`
--

CREATE TABLE `conversation_participants` (
  `conversation_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `last_read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `email_verifications`
--

CREATE TABLE `email_verifications` (
  `id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `email` varchar(190) NOT NULL,
  `verification_code` varchar(10) NOT NULL,
  `expires_at` datetime NOT NULL,
  `verified_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `email_verifications`
--

INSERT INTO `email_verifications` (`id`, `user_id`, `email`, `verification_code`, `expires_at`, `verified_at`, `created_at`) VALUES
(3, 15, 'ssalmaelhayany@gmail.com', '360988', '2026-03-09 14:24:24', '2026-03-09 14:14:50', '2026-03-09 14:14:24'),
(4, 16, 'lakhdym@gmail.com', '538072', '2026-03-09 16:18:44', '2026-03-09 16:10:25', '2026-03-09 16:08:44');

-- --------------------------------------------------------

--
-- Structure de la table `listings`
--

CREATE TABLE `listings` (
  `id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `type` enum('lost','found') NOT NULL,
  `status` enum('draft','pending_payment','published','hidden','archived') NOT NULL DEFAULT 'pending_payment',
  `title` varchar(160) NOT NULL,
  `description` text NOT NULL,
  `category_id` bigint(20) DEFAULT NULL,
  `city` varchar(120) NOT NULL,
  `location_text` varchar(255) DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `event_date` date DEFAULT NULL,
  `contact_chat` tinyint(1) NOT NULL DEFAULT 1,
  `contact_whatsapp` tinyint(1) NOT NULL DEFAULT 1,
  `contact_call` tinyint(1) NOT NULL DEFAULT 1,
  `is_boosted` tinyint(1) NOT NULL DEFAULT 0,
  `published_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `listings`
--

INSERT INTO `listings` (`id`, `user_id`, `type`, `status`, `title`, `description`, `category_id`, `city`, `location_text`, `lat`, `lng`, `event_date`, `contact_chat`, `contact_whatsapp`, `contact_call`, `is_boosted`, `published_at`, `created_at`, `updated_at`) VALUES
(2, 1, 'found', 'published', 'Test API – Portefeuille trouvé', 'Annonce de test insérée automatiquement par dev_insert_sample_listing.php', NULL, 'Casablanca', 'Casablanca, Centre-ville', NULL, NULL, NULL, 1, 1, 1, 0, NULL, '2026-03-03 14:08:05', '2026-03-03 14:08:05');

-- --------------------------------------------------------

--
-- Structure de la table `listing_boosts`
--

CREATE TABLE `listing_boosts` (
  `id` bigint(20) NOT NULL,
  `listing_id` bigint(20) NOT NULL,
  `plan_id` bigint(20) NOT NULL,
  `payment_id` bigint(20) NOT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `listing_comments`
--

CREATE TABLE `listing_comments` (
  `id` bigint(20) NOT NULL,
  `listing_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `content` text NOT NULL,
  `status` enum('visible','hidden') NOT NULL DEFAULT 'visible',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `listing_comments`
--

INSERT INTO `listing_comments` (`id`, `listing_id`, `user_id`, `content`, `status`, `created_at`) VALUES
(1, 2, 2, 'test commentaire', 'visible', '2026-03-05 11:44:23'),
(2, 2, 1, 'Merci ', 'visible', '2026-03-05 11:44:23');

-- --------------------------------------------------------

--
-- Structure de la table `listing_likes`
--

CREATE TABLE `listing_likes` (
  `user_id` bigint(20) NOT NULL,
  `listing_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `listing_likes`
--

INSERT INTO `listing_likes` (`user_id`, `listing_id`, `created_at`) VALUES
(1, 2, '2026-03-05 13:23:24');

-- --------------------------------------------------------

--
-- Structure de la table `listing_photos`
--

CREATE TABLE `listing_photos` (
  `id` bigint(20) NOT NULL,
  `listing_id` bigint(20) NOT NULL,
  `url` varchar(700) NOT NULL,
  `position` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `listing_photos`
--

INSERT INTO `listing_photos` (`id`, `listing_id`, `url`, `position`, `created_at`) VALUES
(1, 2, 'img_test.jpg', 1, '2026-03-04 16:12:51'),
(2, 2, 'image6.jpg', 2, '2026-03-04 17:10:51');

-- --------------------------------------------------------

--
-- Structure de la table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) NOT NULL,
  `conversation_id` bigint(20) NOT NULL,
  `sender_user_id` bigint(20) NOT NULL,
  `message_type` enum('text','image','system') NOT NULL DEFAULT 'text',
  `content` text DEFAULT NULL,
  `media_url` varchar(700) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `payments`
--

CREATE TABLE `payments` (
  `id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `listing_id` bigint(20) DEFAULT NULL,
  `purpose` enum('publish','boost') NOT NULL,
  `provider` enum('cmi','mwallet') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(10) NOT NULL DEFAULT 'MAD',
  `status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `provider_txn_id` varchar(190) DEFAULT NULL,
  `provider_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`provider_payload`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `reports`
--

CREATE TABLE `reports` (
  `id` bigint(20) NOT NULL,
  `reporter_user_id` bigint(20) NOT NULL,
  `target_type` enum('listing','comment','user') NOT NULL,
  `target_id` bigint(20) NOT NULL,
  `reason` enum('spam','scam','abuse','illegal','other') NOT NULL,
  `details` text DEFAULT NULL,
  `status` enum('open','reviewing','resolved','rejected') NOT NULL DEFAULT 'open',
  `handled_by` bigint(20) DEFAULT NULL,
  `handled_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) NOT NULL,
  `role` enum('user','admin') NOT NULL DEFAULT 'user',
  `full_name` varchar(120) NOT NULL,
  `email` varchar(190) NOT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `phone_verified_at` datetime DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `preferred_lang` enum('ar','fr','en') NOT NULL DEFAULT 'fr',
  `is_banned` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `role`, `full_name`, `email`, `email_verified_at`, `phone`, `phone_verified_at`, `password_hash`, `avatar_url`, `preferred_lang`, `is_banned`, `created_at`, `updated_at`) VALUES
(1, 'user', 'Utilisateur Test', 'testuser+69a6eb45918fb@example.com', NULL, NULL, NULL, NULL, NULL, 'fr', 0, '2026-03-03 14:08:05', '2026-03-03 14:08:05'),
(2, 'user', 'azeddine lakhdym', 'azeddine.lakhdym@gmail.com', '2026-02-17 11:35:53', '0645780703', '2026-03-05 11:35:53', NULL, NULL, 'fr', 0, '2026-03-03 14:08:05', '2026-03-03 14:08:05'),
(4, 'user', 'user test', 'salma@gmail.com', NULL, '0652123254', NULL, '$2y$10$/XgiDn4f5iz0e998szwKP.vYoPg6/n16f3upCkwHeqe3PjkbW9aMS', NULL, 'fr', 0, '2026-03-07 14:35:50', '2026-03-07 14:35:50'),
(5, 'user', 'user 2', 'user@gmail.com', NULL, '+21254545632', NULL, '$2y$10$5ndkF9Mw6JDwcRSM72iPS.PBTBujogaqEFUKw9shQlBkBF/1bZgAC', NULL, 'fr', 0, '2026-03-09 12:12:32', '2026-03-09 12:12:32'),
(15, 'user', 'user test', 'ssalmaelhayany@gmail.com', '2026-03-09 14:14:50', '+212709693321', NULL, '$2y$10$VxLRuoCzJ0QhOJxtmpybC.JXA/8t.jXl3CvMtXQneEyL1uqWRf.Ou', NULL, 'fr', 0, '2026-03-09 14:14:24', '2026-03-09 14:14:50'),
(16, 'user', 'azeddine', 'lakhdym@gmail.com', '2026-03-09 16:10:25', '0645780703', NULL, '$2y$10$FIpa1J0K6Mx5NZqc8qiK7Ol4yAfxiZIg2AsCgFGHlaEtPgMHY2G06', NULL, 'fr', 0, '2026-03-09 16:08:44', '2026-03-09 16:10:25');

-- --------------------------------------------------------

--
-- Structure de la table `user_identities`
--

CREATE TABLE `user_identities` (
  `id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `provider` enum('google','apple') NOT NULL,
  `provider_user_id` varchar(190) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `app_settings`
--
ALTER TABLE `app_settings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_settings_admin` (`updated_by`);

--
-- Index pour la table `boost_plans`
--
ALTER TABLE `boost_plans`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_boost_plans_code` (`code`);

--
-- Index pour la table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_categories_slug` (`slug`);

--
-- Index pour la table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_conv_listing` (`listing_id`);

--
-- Index pour la table `conversation_participants`
--
ALTER TABLE `conversation_participants`
  ADD PRIMARY KEY (`conversation_id`,`user_id`),
  ADD KEY `idx_cp_user` (`user_id`);

--
-- Index pour la table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email_verification_user` (`user_id`),
  ADD KEY `idx_email_verification_email` (`email`);

--
-- Index pour la table `listings`
--
ALTER TABLE `listings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_listings_user` (`user_id`),
  ADD KEY `idx_listings_type_status_date` (`type`,`status`,`created_at`),
  ADD KEY `idx_listings_city` (`city`),
  ADD KEY `idx_listings_boosted` (`is_boosted`),
  ADD KEY `fk_listings_category` (`category_id`);

--
-- Index pour la table `listing_boosts`
--
ALTER TABLE `listing_boosts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_boosts_listing` (`listing_id`),
  ADD KEY `idx_boosts_active` (`starts_at`,`ends_at`),
  ADD KEY `fk_boosts_plan` (`plan_id`);

--
-- Index pour la table `listing_comments`
--
ALTER TABLE `listing_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_comments_listing` (`listing_id`,`created_at`),
  ADD KEY `idx_comments_user` (`user_id`);

--
-- Index pour la table `listing_likes`
--
ALTER TABLE `listing_likes`
  ADD PRIMARY KEY (`user_id`,`listing_id`),
  ADD KEY `idx_likes_listing` (`listing_id`);

--
-- Index pour la table `listing_photos`
--
ALTER TABLE `listing_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_photos_listing` (`listing_id`);

--
-- Index pour la table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_msg_conv` (`conversation_id`,`created_at`),
  ADD KEY `idx_msg_sender` (`sender_user_id`);

--
-- Index pour la table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_payments_user` (`user_id`),
  ADD KEY `idx_payments_listing` (`listing_id`),
  ADD KEY `idx_payments_status` (`status`);

--
-- Index pour la table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reports_status` (`status`,`created_at`),
  ADD KEY `idx_reports_target` (`target_type`,`target_id`),
  ADD KEY `fk_reports_reporter` (`reporter_user_id`),
  ADD KEY `fk_reports_admin` (`handled_by`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_phone` (`phone`),
  ADD KEY `idx_users_role` (`role`);

--
-- Index pour la table `user_identities`
--
ALTER TABLE `user_identities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_identity_provider` (`provider`,`provider_user_id`),
  ADD KEY `idx_identity_user` (`user_id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `app_settings`
--
ALTER TABLE `app_settings`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `boost_plans`
--
ALTER TABLE `boost_plans`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `listings`
--
ALTER TABLE `listings`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `listing_boosts`
--
ALTER TABLE `listing_boosts`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `listing_comments`
--
ALTER TABLE `listing_comments`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `listing_photos`
--
ALTER TABLE `listing_photos`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT pour la table `user_identities`
--
ALTER TABLE `user_identities`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `app_settings`
--
ALTER TABLE `app_settings`
  ADD CONSTRAINT `fk_settings_admin` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `fk_conv_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `conversation_participants`
--
ALTER TABLE `conversation_participants`
  ADD CONSTRAINT `fk_cp_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD CONSTRAINT `fk_email_verification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `listings`
--
ALTER TABLE `listings`
  ADD CONSTRAINT `fk_listings_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_listings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `listing_boosts`
--
ALTER TABLE `listing_boosts`
  ADD CONSTRAINT `fk_boosts_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_boosts_plan` FOREIGN KEY (`plan_id`) REFERENCES `boost_plans` (`id`);

--
-- Contraintes pour la table `listing_comments`
--
ALTER TABLE `listing_comments`
  ADD CONSTRAINT `fk_comments_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `listing_likes`
--
ALTER TABLE `listing_likes`
  ADD CONSTRAINT `fk_likes_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_likes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `listing_photos`
--
ALTER TABLE `listing_photos`
  ADD CONSTRAINT `fk_photos_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_msg_sender` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_payments_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_payments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `fk_reports_admin` FOREIGN KEY (`handled_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_reports_reporter` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `user_identities`
--
ALTER TABLE `user_identities`
  ADD CONSTRAINT `fk_identity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
