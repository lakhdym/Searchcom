<?php
// api/likes.php
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
    error_log((string) $e);
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
header('Access-Control-Allow-Methods: GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
if ($auth) {
    // Lecture publique : le token est facultatif. On le valide si prÃ©sent.
    if (preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
        $token = $matches[1];
        verify_jwt($token); // on ignore le payload, simple validation
    }
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

function table_exists_like(PDO $pdo, string $tableName): bool
{
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table
            LIMIT 1
        ");
        $stmt->execute([':table' => $tableName]);
        return (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        return false;
    }
}

if ($method === 'GET') {
    $listingId = isset($_GET['listing_id']) ? (int) $_GET['listing_id'] : 0;
    if ($listingId <= 0) {
        json_response(['error' => 'listing_id requis'], 400);
    }

    if (!table_exists_like($pdo, 'listing_likes')) {
        json_response([]);
    }

    $hasUsersTable = table_exists_like($pdo, 'users');

    $sql = "
        SELECT ll.user_id, ll.listing_id, ll.created_at" . ($hasUsersTable ? ", u.full_name" : "") . "
        FROM listing_likes ll
        " . ($hasUsersTable ? "LEFT JOIN users u ON ll.user_id = u.id" : "") . "
        WHERE ll.listing_id = :listing_id
        ORDER BY ll.created_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':listing_id' => $listingId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $likes = array_map(function ($row) {
        $userId = isset($row['user_id']) ? (int) $row['user_id'] : null;
        $fullName = trim((string) ($row['full_name'] ?? ''));
        if ($fullName === '' && $userId !== null) {
            $fullName = 'Utilisateur #' . $userId;
        }

        return [
            'user_id' => $userId,
            'listing_id' => isset($row['listing_id']) ? (int) $row['listing_id'] : null,
            'full_name' => $fullName,
            'created_at' => $row['created_at'] ?? null,
        ];
    }, $rows);

    json_response($likes);
}

json_response(['error' => 'Method not allowed'], 405);
