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

$body = json_decode(file_get_contents('php://input'), true) ?? [];

$userId      = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$listingId   = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$title       = trim($body['title'] ?? '');
$description = trim($body['description'] ?? '');
$categoryId  = isset($body['category_id']) && $body['category_id'] !== '' ? (int)$body['category_id'] : null;
$city        = trim($body['city'] ?? '');
$location    = trim($body['location_text'] ?? '');
$eventDate   = $body['event_date'] ?? null;
$contactChat      = isset($body['contact_chat']) ? (int)!!$body['contact_chat'] : 1;
$contactWhatsApp  = isset($body['contact_whatsapp']) ? (int)!!$body['contact_whatsapp'] : 1;
$contactCall      = isset($body['contact_call']) ? (int)!!$body['contact_call'] : 1;

if ($userId <= 0 || $listingId <= 0) {
    json_response(['success' => false, 'message' => 'user_id et listing_id requis'], 400);
}
if (mb_strlen($title) < 3 || mb_strlen($description) < 3 || $city === '') {
    json_response(['success' => false, 'message' => 'Titre, description ou ville manquants'], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier l’appartenance
    $check = $pdo->prepare('SELECT user_id, type, status FROM listings WHERE id = ? LIMIT 1');
    $check->execute([$listingId]);
    $row = $check->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
    }
    if ((int)$row['user_id'] !== $userId) {
        json_response(['success' => false, 'message' => 'Accès refusé'], 403);
    }

    $stmt = $pdo->prepare('UPDATE listings
        SET title = :title,
            description = :description,
            category_id = :category_id,
            city = :city,
            location_text = :location_text,
            event_date = :event_date,
            contact_chat = :contact_chat,
            contact_whatsapp = :contact_whatsapp,
            contact_call = :contact_call,
            updated_at = NOW()
        WHERE id = :id');

    $stmt->execute([
        ':title' => $title,
        ':description' => $description,
        ':category_id' => $categoryId,
        ':city' => $city,
        ':location_text' => $location !== '' ? $location : null,
        ':event_date' => $eventDate ?: null,
        ':contact_chat' => $contactChat,
        ':contact_whatsapp' => $contactWhatsApp,
        ':contact_call' => $contactCall,
        ':id' => $listingId,
    ]);

    json_response(['success' => true, 'message' => 'Annonce mise à jour avec succès']);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
