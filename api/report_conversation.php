<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Méthode non autorisée'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$conversationId = isset($body['conversation_id']) ? (int)$body['conversation_id'] : 0;
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$reason = trim($body['reason'] ?? '');

if ($conversationId <= 0 || $userId <= 0 || $reason === '') {
    json_response(['success' => false, 'message' => 'conversation_id, user_id et reason requis'], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier que l'utilisateur fait partie de la conversation
    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Accès refusé à cette conversation'], 403);
    }

    // Table de rapport
    $tableExists = $pdo->query("SHOW TABLES LIKE 'conversation_reports'")->fetchColumn();
    if (!$tableExists) {
        $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_reports (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            conversation_id BIGINT NOT NULL,
            reporter_user_id BIGINT NOT NULL,
            reason VARCHAR(255) NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_conv_user (conversation_id, reporter_user_id),
            CONSTRAINT fk_report_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
            CONSTRAINT fk_report_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    }

    $insert = $pdo->prepare('INSERT INTO conversation_reports (conversation_id, reporter_user_id, reason) VALUES (:cid, :uid, :reason)');
    $insert->execute([':cid' => $conversationId, ':uid' => $userId, ':reason' => $reason]);

    // Bloquer l'autre participant automatiquement
    $blockTable = $pdo->query("SHOW TABLES LIKE 'conversation_blocks'")->fetchColumn();
    if (!$blockTable) {
        $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            conversation_id BIGINT NOT NULL,
            blocker_user_id BIGINT NOT NULL,
            blocked_user_id BIGINT NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id),
            CONSTRAINT fk_block_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
            CONSTRAINT fk_block_blocker FOREIGN KEY (blocker_user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_block_blocked FOREIGN KEY (blocked_user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    }

    // Identifier l'autre participant
    $otherStmt = $pdo->prepare('SELECT user_id FROM conversation_participants WHERE conversation_id = :cid AND user_id <> :uid LIMIT 1');
    $otherStmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    $otherUserId = (int)($otherStmt->fetchColumn() ?: 0);

    if ($otherUserId > 0) {
        $blockInsert = $pdo->prepare('INSERT IGNORE INTO conversation_blocks (conversation_id, blocker_user_id, blocked_user_id) VALUES (:cid, :blocker, :blocked)');
        $blockInsert->execute([':cid' => $conversationId, ':blocker' => $userId, ':blocked' => $otherUserId]);
    }

    json_response(['success' => true, 'message' => 'Signalement enregistré et utilisateur bloqué']);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
