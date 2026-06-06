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
require_once __DIR__ . '/contact_access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Methode non autorisee'], 405);
}

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$isMultipart = stripos($contentType, 'multipart/form-data') !== false;
$body = $isMultipart ? [] : (json_decode(file_get_contents('php://input'), true) ?? []);

$requestedUserId = $isMultipart ? (int)($_POST['user_id'] ?? 0) : (int)($body['user_id'] ?? 0);
$userId = require_authenticated_user_id($requestedUserId > 0 ? $requestedUserId : null);

$conversationId = $isMultipart ? (int)($_POST['conversation_id'] ?? 0) : (int)($body['conversation_id'] ?? 0);
$messageType = strtolower(trim((string)($isMultipart ? ($_POST['message_type'] ?? 'text') : ($body['message_type'] ?? 'text'))));
$contentRaw = $isMultipart ? ($_POST['content'] ?? '') : ($body['content'] ?? '');
$content = is_string($contentRaw) ? trim($contentRaw) : '';
$replyToRaw = $isMultipart ? ($_POST['reply_to_message_id'] ?? null) : ($body['reply_to_message_id'] ?? null);
$replyTo = is_numeric($replyToRaw) ? (int)$replyToRaw : null;

if ($conversationId <= 0) {
    json_response(['success' => false, 'message' => 'conversation_id requis'], 400);
}

$allowedTypes = ['text', 'image'];
if (!in_array($messageType, $allowedTypes, true)) {
    json_response(['success' => false, 'message' => 'message_type invalide'], 400);
}

if ($messageType === 'text' && $content === '') {
    json_response(['success' => false, 'message' => 'content requis'], 400);
}

if ($messageType === 'image') {
    if (!isset($_FILES['image'])) {
        json_response(['success' => false, 'message' => 'Aucune image recue'], 400);
    }
    if ((int)($_FILES['image']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        json_response(['success' => false, 'message' => 'Impossible de recevoir l image'], 400);
    }
}

$uploadedFilePath = null;

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Acces non autorise a cette conversation'], 403);
    }

    $accessStmt = $pdo->prepare('
        SELECT c.listing_id, l.user_id AS owner_id, l.type
        FROM conversations c
        JOIN listings l ON l.id = c.listing_id
        WHERE c.id = :cid
        LIMIT 1
    ');
    $accessStmt->execute([':cid' => $conversationId]);
    $conversationMeta = $accessStmt->fetch(PDO::FETCH_ASSOC);
    if ($conversationMeta &&
        ($conversationMeta['type'] ?? '') === 'found' &&
        (int) ($conversationMeta['owner_id'] ?? 0) !== $userId
    ) {
        if (!user_has_contact_access(
            $pdo,
            $userId,
            (int) ($conversationMeta['listing_id'] ?? 0)
        )) {
            json_response([
                'success' => false,
                'requires_payment' => true,
                'message' => 'Paiement requis pour contacter le publieur',
            ], 403);
        }
    }

    $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        conversation_id BIGINT NOT NULL,
        blocker_user_id BIGINT NOT NULL,
        blocked_user_id BIGINT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $blockStmt = $pdo->prepare('SELECT 1 FROM conversation_blocks WHERE conversation_id = :cid LIMIT 1');
    $blockStmt->execute([':cid' => $conversationId]);
    if ($blockStmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Conversation bloquee'], 403);
    }

    if ($replyTo !== null) {
        $replyStmt = $pdo->prepare('SELECT 1 FROM messages WHERE id = :id AND conversation_id = :cid LIMIT 1');
        $replyStmt->execute([':id' => $replyTo, ':cid' => $conversationId]);
        if (!$replyStmt->fetchColumn()) {
            json_response(['success' => false, 'message' => 'Message de reponse introuvable'], 400);
        }
    }

    $hasReplyColumn = false;
    $columns = $pdo->query("SHOW COLUMNS FROM messages LIKE 'reply_to_message_id'")->fetchAll(PDO::FETCH_ASSOC);
    if ($columns) {
        $hasReplyColumn = true;
    }

    $mediaUrl = null;
    $contentForInsert = $content;

    if ($messageType === 'image') {
        $file = $_FILES['image'];
        $tmpPath = $file['tmp_name'] ?? '';
        if (!is_uploaded_file($tmpPath)) {
            json_response(['success' => false, 'message' => 'Image invalide'], 400);
        }

        $fileSize = (int)($file['size'] ?? 0);
        if ($fileSize <= 0 || $fileSize > 10 * 1024 * 1024) {
            json_response(['success' => false, 'message' => 'Image trop volumineuse'], 400);
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = (string)$finfo->file($tmpPath);
        $allowedMimeTypes = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            'image/gif' => 'gif',
        ];
        if (!isset($allowedMimeTypes[$mimeType])) {
            json_response(['success' => false, 'message' => 'Format d image non supporte'], 400);
        }

        $uploadDir = __DIR__ . '/../uploads/chat';
        if (!is_dir($uploadDir) && !mkdir($uploadDir, 0775, true) && !is_dir($uploadDir)) {
            throw new RuntimeException('Impossible de creer le dossier d upload');
        }

        $fileName = sprintf(
            'chat_%d_%d_%s.%s',
            $conversationId,
            $userId,
            bin2hex(random_bytes(8)),
            $allowedMimeTypes[$mimeType]
        );
        $uploadedFilePath = $uploadDir . DIRECTORY_SEPARATOR . $fileName;
        if (!move_uploaded_file($tmpPath, $uploadedFilePath)) {
            throw new RuntimeException('Impossible de sauvegarder l image');
        }

        $mediaUrl = uploads_url('chat/' . $fileName);
        $contentForInsert = '';
    }

    $pdo->beginTransaction();

    if ($hasReplyColumn) {
        $stmt = $pdo->prepare('INSERT INTO messages (conversation_id, sender_user_id, message_type, content, media_url, reply_to_message_id, created_at) VALUES (:cid, :uid, :type, :content, :media_url, :reply_to, NOW())');
        $stmt->execute([
            ':cid' => $conversationId,
            ':uid' => $userId,
            ':type' => $messageType,
            ':content' => $contentForInsert,
            ':media_url' => $mediaUrl,
            ':reply_to' => $replyTo,
        ]);
    } else {
        $stmt = $pdo->prepare('INSERT INTO messages (conversation_id, sender_user_id, message_type, content, media_url, created_at) VALUES (:cid, :uid, :type, :content, :media_url, NOW())');
        $stmt->execute([
            ':cid' => $conversationId,
            ':uid' => $userId,
            ':type' => $messageType,
            ':content' => $contentForInsert,
            ':media_url' => $mediaUrl,
        ]);
    }
    $msgId = (int)$pdo->lastInsertId();

    $select = 'SELECT id, conversation_id, sender_user_id, message_type, content, media_url, created_at';
    if ($hasReplyColumn) {
        $select .= ', reply_to_message_id';
    }
    $select .= ' FROM messages WHERE id = :id';

    $stmt = $pdo->prepare($select);
    $stmt->execute([':id' => $msgId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new RuntimeException('Message introuvable apres creation');
    }

    if ($row['message_type'] === 'image' && (($row['content'] ?? '') === '')) {
        $row['content'] = null;
    }

    $pdo->commit();

    json_response([
        'success' => true,
        'message' => $messageType === 'image' ? 'Image envoyee' : 'Message envoye',
        'data' => $row,
    ]);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    if ($uploadedFilePath && is_file($uploadedFilePath)) {
        @unlink($uploadedFilePath);
    }
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
