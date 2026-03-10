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
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];

$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$fullName = trim($body['full_name'] ?? '');
$phone = trim($body['phone'] ?? '');
$preferredLang = $body['preferred_lang'] ?? 'fr';
$avatarUrl = trim($body['avatar_url'] ?? '');

$errors = [];
if ($userId <= 0) $errors[] = 'User ID manquant';
if (mb_strlen($fullName) < 2) $errors[] = 'Nom complet invalide';
$allowedLangs = ['fr', 'ar', 'en'];
if (!in_array($preferredLang, $allowedLangs, true)) $errors[] = 'Langue préférée invalide';

if ($errors) {
    json_response(['success' => false, 'message' => implode(', ', $errors)], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier que l'utilisateur existe
    $stmt = $pdo->prepare('SELECT id FROM users WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $userId]);
    if (!$stmt->fetch()) {
        json_response(['success' => false, 'message' => 'Utilisateur introuvable'], 404);
    }

    $now = date('Y-m-d H:i:s');

    $stmt = $pdo->prepare(
        'UPDATE users
         SET full_name = :full_name,
             phone = :phone,
             preferred_lang = :preferred_lang,
             avatar_url = :avatar_url,
             updated_at = :updated_at
         WHERE id = :id'
    );

    $stmt->execute([
        ':full_name' => $fullName,
        ':phone' => $phone ?: null,
        ':preferred_lang' => $preferredLang,
        ':avatar_url' => $avatarUrl ?: null,
        ':updated_at' => $now,
        ':id' => $userId,
    ]);

    // Renvoyer les données mises à jour
    $stmt = $pdo->prepare(
        'SELECT id, role, full_name, email, phone, avatar_url, preferred_lang, is_banned
         FROM users WHERE id = :id LIMIT 1'
    );
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    json_response([
        'success' => true,
        'message' => 'Profil mis à jour avec succès',
        'user' => [
            'id' => (int)$user['id'],
            'role' => $user['role'],
            'full_name' => $user['full_name'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'avatar_url' => $user['avatar_url'],
            'preferred_lang' => $user['preferred_lang'],
            'is_banned' => (int)$user['is_banned'],
        ],
    ]);
} catch (Throwable $e) {
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
