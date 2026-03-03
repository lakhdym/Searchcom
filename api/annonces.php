<?php
// api/annonces.php
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/api_error.log');
error_reporting(E_ALL);

set_exception_handler(function ($e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        "error" => "Server error",
        "details" => $e->getMessage(),
    ]);
    error_log((string)$e);
    exit;
});

set_error_handler(function ($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

header('Content-Type: application/json; charset=UTF-8');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$allowed = [
    'https://italents.ma',
    'https://www.italents.ma',
];

// allow localhost:anyport for Flutter web dev
$isLocalhost = preg_match('#^http://localhost:\d+$#', $origin) || preg_match('#^http://127\.0\.0\.1:\d+$#', $origin);

if ($isLocalhost || in_array($origin, $allowed, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}

header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

// إذا ما كتستعملش cookies/session خليه محيد
// header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
$payload = null;
if (preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
    $token = $matches[1];
    $payload = verify_jwt($token);
    if ($payload === null) {
        json_response(['error' => 'Token invalide ou expiré'], 401);
    }
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

/**
 * Transforme une ligne de la table `listings` en structure JSON simplifiée
 * utilisée par l'app Flutter.
 */
function map_listing_row(array $row): array
{
    return [
        'id' => (int) $row['id'],
        'type' => $row['type'], // lost | found
        'status' => $row['status'],
        'title' => $row['title'],
        'description' => $row['description'],
        'location' => $row['location_text'] ?: $row['city'],
        'city' => $row['city'],
        'date' => $row['created_at'], // YYYY-MM-DD HH:MM:SS
        'is_boosted' => (bool) $row['is_boosted'],
        'imageUrl' => null, // à alimenter plus tard via listing_photos
    ];
}

if ($method === 'GET') {
    // Optionnel : ?type=lost|found
    $type = $_GET['type'] ?? null;

    $sql = "
        SELECT id, type, status, title, description, city, location_text, is_boosted, created_at
        FROM listings
        WHERE status = 'published'
    ";
    $params = [];

    if ($type === 'lost' || $type === 'found') {
        $sql .= " AND type = :type";
        $params[':type'] = $type;
    }

    $sql .= " ORDER BY created_at DESC LIMIT 50";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    $data = array_map('map_listing_row', $rows);
    json_response($data);
}

if ($method === 'POST') {
    // Les créations nécessitent toujours un utilisateur authentifié
    if ($payload === null) {
        json_response(['error' => 'Token manquant'], 401);
    }

    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $type = $body['type'] ?? null; // lost | found
    $title = trim($body['title'] ?? '');
    $description = trim($body['description'] ?? '');
    $location = trim($body['location'] ?? '');
    $city = trim($body['city'] ?? $location);

    if (!in_array($type, ['lost', 'found'], true)) {
        json_response(['error' => 'Type invalide (lost|found requis)'], 400);
    }
    if ($title === '' || $description === '' || $city === '') {
        json_response(['error' => 'Champs requis manquants (title, description, location/city)'], 400);
    }

    // Status selon le type :
    // - lost  => pending_payment (paiement 10 DH requis)
    // - found => published directement
    $status = $type === 'lost' ? 'pending_payment' : 'published';

    $userId = isset($payload['sub']) ? (int) $payload['sub'] : 0;
    if ($userId <= 0) {
        json_response(['error' => 'Utilisateur invalide dans le token'], 401);
    }

    $now = date('Y-m-d H:i:s');

    $sql = "
        INSERT INTO listings (
            user_id,
            type,
            status,
            title,
            description,
            category_id,
            city,
            location_text,
            contact_chat,
            contact_whatsapp,
            contact_call,
            is_boosted,
            created_at,
            updated_at
        ) VALUES (
            :user_id,
            :type,
            :status,
            :title,
            :description,
            NULL,
            :city,
            :location_text,
            1,
            1,
            1,
            0,
            :created_at,
            :created_at
        )
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':user_id' => $userId,
        ':type' => $type,
        ':status' => $status,
        ':title' => $title,
        ':description' => $description,
        ':city' => $city,
        ':location_text' => $location !== '' ? $location : $city,
        ':created_at' => $now,
    ]);

    $id = (int) $pdo->lastInsertId();

    // Récupérer la ligne insérée pour renvoyer un objet cohérent
    $stmt = $pdo->prepare("
        SELECT id, type, status, title, description, city, location_text, is_boosted, created_at
        FROM listings
        WHERE id = :id
    ");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();

    if (!$row) {
        json_response(['error' => "Impossible de récupérer l'annonce créée"], 500);
    }

    $data = map_listing_row($row);
    json_response($data, 201);
}

json_response(['error' => 'Method not allowed'], 405);
