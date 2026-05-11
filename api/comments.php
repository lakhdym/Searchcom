<?php

header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

require_once __DIR__ . '/comment_utils.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    if ($method === 'GET') {
        $listingId = isset($_GET['listing_id']) ? (int) $_GET['listing_id'] : 0;
        if ($listingId <= 0) {
            json_response(['success' => false, 'message' => 'listing_id requis'], 400);
        }

        json_response(fetch_listing_comments($pdo, $listingId));
    }

    if ($method === 'POST') {
        $userId = require_authenticated_user_id();
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;
        $content = trim((string) ($body['content'] ?? ''));

        if ($listingId <= 0 || $content === '') {
            json_response(['success' => false, 'message' => 'listing_id et content requis'], 400);
        }

        if (!comment_listing_exists($pdo, $listingId)) {
            json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
        }

        $now = date('Y-m-d H:i:s');
        $stmt = $pdo->prepare("
            INSERT INTO listing_comments (
                listing_id,
                user_id,
                content,
                status,
                created_at,
                updated_at,
                deleted_at,
                deleted_by_user_id
            ) VALUES (
                :listing_id,
                :user_id,
                :content,
                'visible',
                :created_at,
                NULL,
                NULL,
                NULL
            )
        ");
        $stmt->execute([
            ':listing_id' => $listingId,
            ':user_id' => $userId,
            ':content' => $content,
            ':created_at' => $now,
        ]);

        $commentId = (int) $pdo->lastInsertId();
        $comment = fetch_comment_payload($pdo, $commentId);
        if ($comment === null) {
            json_response(['success' => false, 'message' => 'Commentaire introuvable'], 500);
        }

        json_response($comment, 201);
    }

    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur'], 500);
}
