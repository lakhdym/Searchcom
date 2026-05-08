<?php

require_once __DIR__ . '/config.php';

function notification_index_exists(PDO $pdo, string $tableName, string $indexName): bool
{
    static $cache = [];
    $key = $tableName . '.' . $indexName;
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table_name
              AND INDEX_NAME = :index_name
            LIMIT 1
        ");
        $stmt->execute([
            ':table_name' => $tableName,
            ':index_name' => $indexName,
        ]);
        $cache[$key] = (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        $cache[$key] = false;
    }

    return $cache[$key];
}

function ensure_notification_schema(PDO $pdo): void
{
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS listing_likes (
            user_id BIGINT NOT NULL,
            listing_id BIGINT NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, listing_id),
            KEY idx_likes_listing (listing_id),
            KEY idx_likes_listing_created (listing_id, created_at),
            KEY idx_likes_user_created (user_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    if (!notification_index_exists($pdo, 'listing_likes', 'idx_likes_listing')) {
        try {
            $pdo->exec("
                ALTER TABLE listing_likes
                ADD INDEX idx_likes_listing (listing_id)
            ");
        } catch (Throwable $e) {
        }
    }

    if (!notification_index_exists($pdo, 'listing_likes', 'idx_likes_listing_created')) {
        try {
            $pdo->exec("
                ALTER TABLE listing_likes
                ADD INDEX idx_likes_listing_created (listing_id, created_at)
            ");
        } catch (Throwable $e) {
        }
    }

    if (!notification_index_exists($pdo, 'listing_likes', 'idx_likes_user_created')) {
        try {
            $pdo->exec("
                ALTER TABLE listing_likes
                ADD INDEX idx_likes_user_created (user_id, created_at)
            ");
        } catch (Throwable $e) {
        }
    }

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS notification_reads (
            user_id BIGINT PRIMARY KEY,
            last_seen_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
}
