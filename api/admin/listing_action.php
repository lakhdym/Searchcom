<?php
// Admin actions for listings: view / delete (soft archive)
header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); echo json_encode(['ok'=>true]); exit; }

require_once __DIR__ . '/../config.php';

function respond($ok, $message, $extra = [], $status = 200) {
    http_response_code($status);
    echo json_encode(array_merge(['success'=>$ok, 'message'=>$message], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $body = json_decode(file_get_contents('php://input'), true);
    if (!is_array($body)) respond(false, 'Payload JSON invalide', [], 400);
    $action = $body['action'] ?? null;
    $id = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
    if (!$action || $id <= 0) respond(false, 'Action ou listing_id manquant', [], 400);

    $pdo = get_pdo();

    switch ($action) {
        case 'view':
            $stmt = $pdo->prepare("SELECT l.id, l.title, l.type, l.status, l.city, l.location_text, l.is_boosted, l.created_at,
                                          l.event_date, l.description, u.full_name AS user_name, u.email AS user_email,
                                          c.name_fr AS category
                                   FROM listings l
                                   LEFT JOIN users u ON u.id = l.user_id
                                   LEFT JOIN categories c ON c.id = l.category_id
                                   WHERE l.id = :id LIMIT 1");
            $stmt->execute([':id'=>$id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) respond(false, 'Annonce introuvable', [], 404);
            // photos
            $pstmt = $pdo->prepare("SELECT url FROM listing_photos WHERE listing_id = :id ORDER BY position ASC, id ASC");
            $pstmt->execute([':id'=>$id]);
            $photos = $pstmt->fetchAll(PDO::FETCH_COLUMN);
            $row['photos'] = $photos ?: [];
            respond(true, 'OK', ['listing'=>$row]);
            break;

        case 'delete':
            // Soft archive
            $pdo->prepare("UPDATE listings SET status='archived', is_boosted=0 WHERE id=:id")->execute([':id'=>$id]);
            respond(true, 'Annonce archivée', ['status'=>'archived']);
            break;

        case 'edit':
            // Update status only (as requested)
            $fields = [];
            $params = [':id'=>$id];
            if (isset($body['status']) && $body['status'] !== '') {
                $fields[] = "status = :status";
                $params[':status'] = $body['status'];
            }
            if (!$fields) respond(false, 'Aucun champ à mettre à jour', [], 400);
            $pdo->prepare("UPDATE listings SET ".implode(',', $fields)." WHERE id = :id")->execute($params);
            respond(true, 'Annonce mise à jour', ['updated_fields'=>array_keys($params)]);
            break;

        default:
            respond(false, 'Action inconnue', [], 400);
    }
} catch (Throwable $e) {
    error_log('[admin/listing_action] '.$e->getMessage());
    respond(false, 'Erreur serveur', ['error'=>$e->getMessage()], 500);
}
