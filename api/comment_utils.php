<?php

require_once __DIR__ . '/config.php';

function comment_table_exists(PDO $pdo, string $tableName): bool
{
    static $cache = [];
    if (array_key_exists($tableName, $cache)) {
        return $cache[$tableName];
    }

    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table_name
            LIMIT 1
        ");
        $stmt->execute([':table_name' => $tableName]);
        $cache[$tableName] = (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        $cache[$tableName] = false;
    }

    return $cache[$tableName];
}

function comment_column_exists(PDO $pdo, string $tableName, string $columnName): bool
{
    static $cache = [];
    $key = $tableName . '.' . $columnName;
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table_name
              AND COLUMN_NAME = :column_name
            LIMIT 1
        ");
        $stmt->execute([
            ':table_name' => $tableName,
            ':column_name' => $columnName,
        ]);
        $cache[$key] = (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        $cache[$key] = false;
    }

    return $cache[$key];
}

function comment_index_exists(PDO $pdo, string $tableName, string $indexName): bool
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

function comment_first_existing_column(PDO $pdo, string $tableName, array $columnNames): ?string
{
    foreach ($columnNames as $columnName) {
        if (comment_column_exists($pdo, $tableName, $columnName)) {
            return $columnName;
        }
    }

    return null;
}

function ensure_comment_schema(PDO $pdo): void
{
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS listing_comments (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            listing_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            content TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'visible',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    if (!comment_column_exists($pdo, 'listing_comments', 'updated_at')) {
        $pdo->exec("
            ALTER TABLE listing_comments
            ADD COLUMN updated_at DATETIME NULL DEFAULT NULL AFTER created_at
        ");
    }

    if (!comment_column_exists($pdo, 'listing_comments', 'deleted_at')) {
        $pdo->exec("
            ALTER TABLE listing_comments
            ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL AFTER updated_at
        ");
    }

    if (!comment_column_exists($pdo, 'listing_comments', 'deleted_by_user_id')) {
        $pdo->exec("
            ALTER TABLE listing_comments
            ADD COLUMN deleted_by_user_id BIGINT NULL DEFAULT NULL AFTER deleted_at
        ");
    }

    if (!comment_index_exists($pdo, 'listing_comments', 'idx_comments_listing_visibility')) {
        $pdo->exec("
            ALTER TABLE listing_comments
            ADD INDEX idx_comments_listing_visibility (listing_id, deleted_at, created_at)
        ");
    }

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS comment_edits (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            comment_id BIGINT NOT NULL,
            editor_user_id BIGINT NOT NULL,
            old_content TEXT NOT NULL,
            new_content TEXT NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_comment_edits_comment (comment_id, created_at),
            INDEX idx_comment_edits_editor (editor_user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $legacyEditCommentIdColumn = comment_first_existing_column($pdo, 'comment_edits', [
        'target_id',
        'listing_comment_id',
    ]);
    if (!comment_column_exists($pdo, 'comment_edits', 'comment_id')) {
        $pdo->exec("
            ALTER TABLE comment_edits
            ADD COLUMN comment_id BIGINT NULL DEFAULT NULL AFTER id
        ");

        if ($legacyEditCommentIdColumn !== null) {
            $pdo->exec("
                UPDATE comment_edits
                SET comment_id = COALESCE(comment_id, {$legacyEditCommentIdColumn})
            ");
        }
    }

    $legacyEditorColumn = comment_first_existing_column($pdo, 'comment_edits', [
        'user_id',
        'updated_by_user_id',
        'created_by',
    ]);
    if (!comment_column_exists($pdo, 'comment_edits', 'editor_user_id')) {
        $pdo->exec("
            ALTER TABLE comment_edits
            ADD COLUMN editor_user_id BIGINT NULL DEFAULT NULL AFTER comment_id
        ");

        if ($legacyEditorColumn !== null) {
            $pdo->exec("
                UPDATE comment_edits
                SET editor_user_id = COALESCE(editor_user_id, {$legacyEditorColumn})
            ");
        }
    }

    $legacyOldContentColumn = comment_first_existing_column($pdo, 'comment_edits', [
        'previous_content',
        'content_before',
        'old_text',
    ]);
    if (!comment_column_exists($pdo, 'comment_edits', 'old_content')) {
        $pdo->exec("
            ALTER TABLE comment_edits
            ADD COLUMN old_content TEXT NULL AFTER editor_user_id
        ");

        if ($legacyOldContentColumn !== null) {
            $pdo->exec("
                UPDATE comment_edits
                SET old_content = COALESCE(old_content, {$legacyOldContentColumn})
            ");
        }
    }

    $legacyNewContentColumn = comment_first_existing_column($pdo, 'comment_edits', [
        'content',
        'updated_content',
        'content_after',
        'new_text',
    ]);
    if (!comment_column_exists($pdo, 'comment_edits', 'new_content')) {
        $pdo->exec("
            ALTER TABLE comment_edits
            ADD COLUMN new_content TEXT NULL AFTER old_content
        ");

        if ($legacyNewContentColumn !== null) {
            $pdo->exec("
                UPDATE comment_edits
                SET new_content = COALESCE(new_content, {$legacyNewContentColumn})
            ");
        }
    }

    if (!comment_column_exists($pdo, 'comment_edits', 'created_at')) {
        $pdo->exec("
            ALTER TABLE comment_edits
            ADD COLUMN created_at DATETIME NULL DEFAULT NULL AFTER new_content
        ");
    }

    if (!comment_index_exists($pdo, 'comment_edits', 'idx_comment_edits_comment')) {
        try {
            $pdo->exec("
                ALTER TABLE comment_edits
                ADD INDEX idx_comment_edits_comment (comment_id, created_at)
            ");
        } catch (Throwable $e) {
        }
    }

    if (!comment_index_exists($pdo, 'comment_edits', 'idx_comment_edits_editor')) {
        try {
            $pdo->exec("
                ALTER TABLE comment_edits
                ADD INDEX idx_comment_edits_editor (editor_user_id)
            ");
        } catch (Throwable $e) {
        }
    }

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS comment_reports (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            comment_id BIGINT NOT NULL,
            reporter_user_id BIGINT NOT NULL,
            reason VARCHAR(30) NOT NULL,
            details TEXT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'open',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_comment_reporter (comment_id, reporter_user_id),
            INDEX idx_comment_reports_status (status, created_at),
            INDEX idx_comment_reports_comment (comment_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $legacyCommentIdColumn = comment_first_existing_column($pdo, 'comment_reports', [
        'target_id',
        'listing_comment_id',
    ]);
    if (!comment_column_exists($pdo, 'comment_reports', 'comment_id')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN comment_id BIGINT NULL DEFAULT NULL AFTER id
        ");

        if ($legacyCommentIdColumn !== null) {
            $pdo->exec("
                UPDATE comment_reports
                SET comment_id = COALESCE(comment_id, {$legacyCommentIdColumn})
            ");
        }
    }

    $legacyReporterColumn = comment_first_existing_column($pdo, 'comment_reports', [
        'user_id',
        'reported_by_user_id',
        'created_by',
    ]);
    if (!comment_column_exists($pdo, 'comment_reports', 'reporter_user_id')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN reporter_user_id BIGINT NULL DEFAULT NULL AFTER comment_id
        ");

        if ($legacyReporterColumn !== null) {
            $pdo->exec("
                UPDATE comment_reports
                SET reporter_user_id = COALESCE(reporter_user_id, {$legacyReporterColumn})
            ");
        }
    }

    if (!comment_column_exists($pdo, 'comment_reports', 'reason')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN reason VARCHAR(30) NULL DEFAULT NULL AFTER reporter_user_id
        ");
    }

    if (!comment_column_exists($pdo, 'comment_reports', 'details')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN details TEXT NULL AFTER reason
        ");
    }

    if (!comment_column_exists($pdo, 'comment_reports', 'status')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'open' AFTER details
        ");
    }

    if (!comment_column_exists($pdo, 'comment_reports', 'created_at')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN created_at DATETIME NULL DEFAULT NULL AFTER status
        ");
    }

    if (!comment_column_exists($pdo, 'comment_reports', 'updated_at')) {
        $pdo->exec("
            ALTER TABLE comment_reports
            ADD COLUMN updated_at DATETIME NULL DEFAULT NULL AFTER created_at
        ");
    }

    if (!comment_index_exists($pdo, 'comment_reports', 'idx_comment_reports_status')) {
        try {
            $pdo->exec("
                ALTER TABLE comment_reports
                ADD INDEX idx_comment_reports_status (status, created_at)
            ");
        } catch (Throwable $e) {
        }
    }

    if (!comment_index_exists($pdo, 'comment_reports', 'idx_comment_reports_comment')) {
        try {
            $pdo->exec("
                ALTER TABLE comment_reports
                ADD INDEX idx_comment_reports_comment (comment_id)
            ");
        } catch (Throwable $e) {
        }
    }

    if (!comment_index_exists($pdo, 'comment_reports', 'uniq_comment_reporter')) {
        try {
            $pdo->exec("
                ALTER TABLE comment_reports
                ADD UNIQUE KEY uniq_comment_reporter (comment_id, reporter_user_id)
            ");
        } catch (Throwable $e) {
        }
    }
}

function comment_placeholder_text(): string
{
    return 'comment_deleted';
}

function normalize_comment_row(array $row): array
{
    $deletedAt = $row['deleted_at'] ?? null;
    $status = strtolower(trim((string) ($row['status'] ?? 'visible')));
    $isDeleted = !empty($deletedAt) || $status === 'deleted';
    $content = $isDeleted ? '' : (string) ($row['content'] ?? '');
    $editsCount = (int) ($row['edits_count'] ?? 0);
    $updatedAt = $row['updated_at'] ?? null;
    $isEdited = !$isDeleted && ($editsCount > 0 || !empty($updatedAt));

    return [
        'id' => (int) ($row['id'] ?? 0),
        'listing_id' => (int) ($row['listing_id'] ?? 0),
        'user_id' => isset($row['user_id']) ? (int) $row['user_id'] : null,
        'full_name' => (string) ($row['full_name'] ?? ''),
        'content' => $content,
        'status' => $isDeleted ? 'deleted' : ($isEdited ? 'edited' : ($row['status'] ?? 'visible')),
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $updatedAt,
        'deleted_at' => $deletedAt,
        'deleted_by_user_id' => isset($row['deleted_by_user_id']) ? (int) $row['deleted_by_user_id'] : null,
        'is_deleted' => $isDeleted,
        'is_edited' => $isEdited,
        'edits_count' => $editsCount,
        'display_key' => $isDeleted ? comment_placeholder_text() : null,
    ];
}

function fetch_comment_row(PDO $pdo, int $commentId): ?array
{
    $stmt = $pdo->prepare("
        SELECT
            c.id,
            c.listing_id,
            c.user_id,
            c.content,
            c.status,
            c.created_at,
            c.updated_at,
            c.deleted_at,
            c.deleted_by_user_id,
            u.full_name,
            (
                SELECT COUNT(*)
                FROM comment_edits ce
                WHERE ce.comment_id = c.id
            ) AS edits_count
        FROM listing_comments c
        LEFT JOIN users u ON u.id = c.user_id
        WHERE c.id = :comment_id
        LIMIT 1
    ");
    $stmt->execute([':comment_id' => $commentId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return is_array($row) ? $row : null;
}

function fetch_listing_comments(PDO $pdo, int $listingId): array
{
    $stmt = $pdo->prepare("
        SELECT
            c.id,
            c.listing_id,
            c.user_id,
            c.content,
            c.status,
            c.created_at,
            c.updated_at,
            c.deleted_at,
            c.deleted_by_user_id,
            u.full_name,
            (
                SELECT COUNT(*)
                FROM comment_edits ce
                WHERE ce.comment_id = c.id
            ) AS edits_count
        FROM listing_comments c
        LEFT JOIN users u ON u.id = c.user_id
        WHERE c.listing_id = :listing_id
          AND (
              c.deleted_at IS NOT NULL
              OR COALESCE(c.status, 'visible') <> 'hidden'
          )
        ORDER BY c.created_at DESC
    ");
    $stmt->execute([':listing_id' => $listingId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    return array_map('normalize_comment_row', $rows ?: []);
}

function fetch_comment_payload(PDO $pdo, int $commentId): ?array
{
    $row = fetch_comment_row($pdo, $commentId);
    return $row === null ? null : normalize_comment_row($row);
}

function comment_listing_exists(PDO $pdo, int $listingId): bool
{
    $stmt = $pdo->prepare('SELECT id FROM listings WHERE id = :listing_id LIMIT 1');
    $stmt->execute([':listing_id' => $listingId]);
    return (bool) $stmt->fetchColumn();
}
