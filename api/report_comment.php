<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'POST') === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

require_once __DIR__ . '/comment_utils.php';

if (($_SERVER['REQUEST_METHOD'] ?? 'POST') !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    $userId = require_authenticated_user_id();
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $commentId = isset($body['comment_id']) ? (int) $body['comment_id'] : 0;
    $reason = trim((string) ($body['reason'] ?? ''));
    $details = trim((string) ($body['details'] ?? ''));
    $allowedReasons = ['spam', 'scam', 'abuse', 'illegal', 'other'];

    if ($commentId <= 0) {
        json_response(['success' => false, 'message' => 'comment_id requis'], 400);
    }
    if (!in_array($reason, $allowedReasons, true)) {
        json_response(['success' => false, 'message' => 'reason invalide'], 400);
    }

    $comment = fetch_comment_row($pdo, $commentId);
    if ($comment === null) {
        json_response(['success' => false, 'message' => 'Commentaire introuvable'], 404);
    }

    if ((int) ($comment['user_id'] ?? 0) === $userId) {
        json_response(['success' => false, 'message' => 'Vous ne pouvez pas signaler votre propre commentaire'], 403);
    }

    $existingStmt = $pdo->prepare("
        SELECT id
        FROM comment_reports
        WHERE comment_id = :comment_id
          AND reporter_user_id = :reporter_user_id
        ORDER BY id DESC
        LIMIT 1
    ");
    $existingStmt->execute([
        ':comment_id' => $commentId,
        ':reporter_user_id' => $userId,
    ]);
    $existingReportId = (int) ($existingStmt->fetchColumn() ?: 0);

    if ($existingReportId > 0) {
        $stmt = $pdo->prepare("
            UPDATE comment_reports
            SET reason = :reason,
                details = :details,
                status = 'open',
                updated_at = NOW()
            WHERE id = :report_id
        ");
        $stmt->execute([
            ':report_id' => $existingReportId,
            ':reason' => $reason,
            ':details' => $details,
        ]);
    } else {
        $stmt = $pdo->prepare("
            INSERT INTO comment_reports (
                comment_id,
                reporter_user_id,
                reason,
                details,
                status,
                created_at,
                updated_at
            ) VALUES (
                :comment_id,
                :reporter_user_id,
                :reason,
                :details,
                'open',
                NOW(),
                NOW()
            )
        ");
        $stmt->execute([
            ':comment_id' => $commentId,
            ':reporter_user_id' => $userId,
            ':reason' => $reason,
            ':details' => $details,
        ]);
    }

    json_response([
        'success' => true,
        'message' => 'Signalement envoye',
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => $e->getMessage() . ' Erreur serveur'], 500);
}
