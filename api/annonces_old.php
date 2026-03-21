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
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

// إذا ما كتستعملش cookies/session خليـه محيد
// header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
$payload = null;


$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

/**
 * Transforme une ligne de la table `listings` en structure JSON simplifiée
 * utilisée par l'app Flutter.
 */
function map_listing_row(
    array $row,
    array $imagesByListingId = [],
    array $commentsByListingId = [],
    array $likesByListingId = [],
    array $likedByUser = []
): array {
    $listingId = (int) $row['id'];
    $images = $imagesByListingId[$listingId] ?? [];
    $mainImage = $images[0] ?? null;

    return [
        'id' => $listingId,
        'user_id' => (int) $row['user_id'],
        'owner_name' => $row['owner_name'] ?? null,
        'type' => $row['type'], // lost | found
        'status' => $row['status'],
        'title' => $row['title'],
        'description' => $row['description'],
        'location' => $row['location_text'] ?: $row['city'],
        'city' => $row['city'],
        'date' => $row['created_at'], // YYYY-MM-DD HH:MM:SS
        'is_boosted' => (bool) $row['is_boosted'],
        // Compat: champ simple (ancien) + nouveau tableau complet
        'imageUrl' => $mainImage,
        'images' => $images,
        'comments_count' => (int) ($commentsByListingId[$listingId] ?? ($row['comments_count'] ?? 0)),
        'likes_count' => (int) ($likesByListingId[$listingId] ?? ($row['likes_count'] ?? 0)),
        'liked_by_me' => isset($likedByUser[$listingId]) ? true : false,
        'contact_chat' => isset($row['contact_chat']) ? (int)$row['contact_chat'] : 0,
        'contact_whatsapp' => isset($row['contact_whatsapp']) ? (int)$row['contact_whatsapp'] : 0,
        'contact_call' => isset($row['contact_call']) ? (int)$row['contact_call'] : 0,
        'owner_phone' => $row['owner_phone'] ?? null,
    ];
}

/**
 * Convertit une URL relative (stockée dans la BD) en URL absolue pour le client.
 */
function absolutize_url(string $url): string
{
    if ($url === '') {
        return $url;
    }

    if (preg_match('#^https?://#i', $url)) {
        return $url;
    }

    // Si on stocke juste le nom de fichier, on préfixe avec la base publique.
    if ($url[0] !== '/' && defined('PHOTO_BASE_URL')) {
        return photo_url($url);
    }

    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? ($_SERVER['SERVER_NAME'] ?? 'localhost');

    // On se base sur la racine du domaine (et pas /api) pour couvrir les chemins du style "uploads/..."
    return $scheme . '://' . $host . '/' . ltrim($url, '/');
}

/**
 * Récupère toutes les photos associées à un ensemble d'annonces.
 * Renvoie un tableau [listing_id => ['url1', 'url2', ...]].
 */
function fetch_listing_images(PDO $pdo, array $listingIds): array
{
    if (empty($listingIds)) {
        return [];
    }

    // Vérifier si la table listing_photos existe dans la base courante
    $tableExists = false;
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'listing_photos'
            LIMIT 1
        ");
        $stmt->execute();
        $tableExists = (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        // On ne bloque pas la réponse si le schéma est différent
        return [];
    }

    if (!$tableExists) {
        return [];
    }

    // Détecter les noms de colonnes disponibles pour l'URL et la clef étrangère
    $columns = [];
    try {
        $stmtCols = $pdo->query("SHOW COLUMNS FROM listing_photos");
        $columns = $stmtCols ? $stmtCols->fetchAll(PDO::FETCH_COLUMN, 0) : [];
    } catch (Throwable $e) {
        return [];
    }

    $imgColCandidates = ['url', 'photo_url', 'image_url', 'file_path', 'path', 'filename'];
    $idColCandidates = ['listing_id', 'listingId', 'listingID'];
    $orderColCandidates = ['sort_order', 'position', 'ordre', 'order_index'];

    $imageCol = null;
    foreach ($imgColCandidates as $c) {
        if (in_array($c, $columns, true)) {
            $imageCol = $c;
            break;
        }
    }
    $listingIdCol = null;
    foreach ($idColCandidates as $c) {
        if (in_array($c, $columns, true)) {
            $listingIdCol = $c;
            break;
        }
    }

    if ($imageCol === null || $listingIdCol === null) {
        return [];
    }

    $orderCol = null;
    foreach ($orderColCandidates as $c) {
        if (in_array($c, $columns, true)) {
            $orderCol = $c;
            break;
        }
    }
    if ($orderCol === null && in_array('id', $columns, true)) {
        $orderCol = 'id';
    }

    $placeholders = implode(',', array_fill(0, count($listingIds), '?'));
    $orderSql = $orderCol ? " ORDER BY `id`" : '';

    $sql = "
        SELECT  listing_id, `url` AS image_url
        FROM listing_photos
        WHERE `listing_id` IN ($placeholders)
        $orderSql
    ";

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute(array_values($listingIds));
    } catch (Throwable $e) {
        // Si la requête échoue (colonne manquante, etc.), on ignore les images
        error_log('[annonces.php] listing_photos query failed: ' . $e->getMessage());
        return [];
    }

    $imagesByListing = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $url = trim((string) ($row['image_url'] ?? ''));
        if ($url === '') {
            continue;
        }
        $listingId = (int) ($row['listing_id'] ?? 0);
        if ($listingId <= 0) {
            continue;
        }
        $imagesByListing[$listingId][] = absolutize_url($url);
    }

    return $imagesByListing;
}

/**
 * RÃ©cupÃ¨re le nombre de commentaires par annonce.
 * Renvoie un tableau [listing_id => count].
 */
function fetch_comments_counts(PDO $pdo, array $listingIds): array
{
    if (empty($listingIds)) {
        return [];
    }

    // VÃ©rifier si la table listing_comments existe
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'listing_comments'
            LIMIT 1
        ");
        $stmt->execute();
        if (!$stmt->fetchColumn()) {
            return [];
        }
    } catch (Throwable $e) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($listingIds), '?'));
    $sql = "
        SELECT listing_id, COUNT(*) AS cnt
        FROM listing_comments
        WHERE listing_id IN ($placeholders)
        GROUP BY listing_id
    ";

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute(array_values($listingIds));
    } catch (Throwable $e) {
        return [];
    }

    $counts = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $lid = (int) ($row['listing_id'] ?? 0);
        if ($lid > 0) {
            $counts[$lid] = (int) ($row['cnt'] ?? 0);
        }
    }

    return $counts;
}

/**
 * RÃ©cupÃ¨re le nombre de likes par annonce.
 * Renvoie un tableau [listing_id => count].
 */
function fetch_likes_counts(PDO $pdo, array $listingIds): array
{
    if (empty($listingIds)) {
        return [];
    }

    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'listing_likes'
            LIMIT 1
        ");
        $stmt->execute();
        if (!$stmt->fetchColumn()) {
            return [];
        }
    } catch (Throwable $e) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($listingIds), '?'));
    $sql = "
        SELECT listing_id, COUNT(*) AS cnt
        FROM listing_likes
        WHERE listing_id IN ($placeholders)
        GROUP BY listing_id
    ";

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute(array_values($listingIds));
    } catch (Throwable $e) {
        return [];
    }

    $counts = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $lid = (int) ($row['listing_id'] ?? 0);
        if ($lid > 0) {
            $counts[$lid] = (int) ($row['cnt'] ?? 0);
        }
    }

    return $counts;
}

/**
 * Renvoie la liste des annonces likÃ©es par l'utilisateur connectÃ©.
 * Retourne un tableau [listing_id => true].
 */
function fetch_user_likes(PDO $pdo, array $listingIds, int $userId): array
{
    if ($userId <= 0 || empty($listingIds)) {
        return [];
    }

    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'listing_likes'
            LIMIT 1
        ");
        $stmt->execute();
        if (!$stmt->fetchColumn()) {
            return [];
        }
    } catch (Throwable $e) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($listingIds), '?'));
    $sql = "
        SELECT listing_id
        FROM listing_likes
        WHERE user_id = ?
          AND listing_id IN ($placeholders)
    ";

    try {
        $params = array_merge([$userId], array_values($listingIds));
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    } catch (Throwable $e) {
        return [];
    }

    $liked = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $lid = (int) ($row['listing_id'] ?? 0);
        if ($lid > 0) {
            $liked[$lid] = true;
        }
    }

    return $liked;
}

if ($method === 'GET') {
    if (preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
        $payload = verify_jwt($matches[1]);
    }

    // Optionnel : ?type=lost|found
    $type = $_GET['type'] ?? null;
    $limit = isset($_GET['limit']) ? (int) $_GET['limit'] : 5;
    $offset = isset($_GET['offset']) ? (int) $_GET['offset'] : 0;
    $limit = max(1, min($limit, 50));
    $offset = max(0, $offset);

    $sql = "
        SELECT l.id,
               l.user_id,
               u.full_name AS owner_name,
               l.type,
               l.status,
               l.title,
               l.description,
               l.city,
               l.location_text,
               l.is_boosted,
               l.contact_chat,
               l.contact_whatsapp,
               l.contact_call,
               u.phone AS owner_phone,
               l.created_at
        FROM listings l
        LEFT JOIN users u ON u.id = l.user_id
        WHERE l.status = 'published'
    ";
    $params = [];

    if ($type === 'lost' || $type === 'found') {
        $sql .= " AND l.type = :type";
        $params[':type'] = $type;
    }

    $sql .= " ORDER BY l.created_at DESC, l.id DESC LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();

    $listingIds = array_map(fn($r) => (int) $r['id'], $rows);
    $imagesByListingId = fetch_listing_images($pdo, $listingIds);
    $commentsByListingId = fetch_comments_counts($pdo, $listingIds);
    $likesByListingId = fetch_likes_counts($pdo, $listingIds);
    $likedByUser = [];
    $userIdForLike = isset($payload['sub']) ? (int) $payload['sub'] : 0;
    if ($userIdForLike > 0) {
        $likedByUser = fetch_user_likes($pdo, $listingIds, $userIdForLike);
    }

    $data = array_map(
        fn($row) => map_listing_row(
            $row,
            $imagesByListingId,
            $commentsByListingId,
            $likesByListingId,
            $likedByUser
        ),
        $rows
    );
    json_response($data);
}

if ($method === 'POST') {

    if (preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
        $token = $matches[1];
        $payload = verify_jwt($token);
        if ($payload === null) {
            json_response(['error' => 'Token invalide ou expiré'], 401);
        }
    }

    // Les créations nécessitent toujours un utilisateur authentifié


    $body = json_decode(file_get_contents('php://input'), true) ?? [];

    $type = $body['type'] ?? null; // lost | found
    $title = trim($body['title'] ?? '');
    $description = trim($body['description'] ?? '');
    $location = trim($body['location_text'] ?? ($body['location'] ?? ''));
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

    // Dans la section POST de api/annonces.php, remplacer l'INSERT par :
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
    lat,
    lng,
    event_date,
    contact_chat,
    contact_whatsapp,
    contact_call,
    is_boosted,
    published_at,
    created_at,
    updated_at
) VALUES (
    :user_id,
    :type,
    :status,
    :title,
    :description,
    :category_id,
    :city,
    :location_text,
    NULL,
    NULL,
    :event_date,
    :contact_chat,
    :contact_whatsapp,
    :contact_call,
    0,
    NOW(),
    :created_at,
    :created_at
)
";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':user_id' => $userId,
        ':type' => $type,
        ':status' => $status, // garde la logique existante (pending_payment pour lost, published pour found)
        ':title' => $title,
        ':description' => $description,
        ':category_id' => $body['category_id'] ?? null,
        ':city' => $city,
        ':location_text' => $location !== '' ? $location : $city,
        ':event_date' => $body['event_date'] ?? null,
        ':contact_chat' => !empty($body['contact_chat']) ? 1 : 0,
        ':contact_whatsapp' => !empty($body['contact_whatsapp']) ? 1 : 0,
        ':contact_call' => !empty($body['contact_call']) ? 1 : 0,
        ':created_at' => $now,
    ]);


    $id = (int) $pdo->lastInsertId();

    if ($type === 'lost') {
        $settings = ['publish_price' => 0, 'currency' => 'MAD'];
        try {
            $stmtSet = $pdo->query("SELECT publish_price, currency FROM app_settings ORDER BY updated_at DESC LIMIT 1");
            if ($stmtSet) {
                $rowSet = $stmtSet->fetch(PDO::FETCH_ASSOC);
                if ($rowSet) {
                    $settings['publish_price'] = $rowSet['publish_price'] ?? 0;
                    $settings['currency'] = $rowSet['currency'] ?? 'MAD';
                }
            }
        } catch (Throwable $e) {
            // keep defaults
        }
        $amount = is_numeric($settings['publish_price']) ? $settings['publish_price'] : 0;
        $currency = $settings['currency'] ?? 'MAD';

        $stmtPay = $pdo->prepare("
            INSERT INTO payments (user_id, listing_id, purpose, provider, amount, currency, status, created_at)
            VALUES (:user_id, :listing_id, 'publish', 'cmi', :amount, :currency, 'pending', NOW())
        ");
        $stmtPay->execute([
            ':user_id' => $userId,
            ':listing_id' => $id,
            ':amount' => $amount,
            ':currency' => $currency,
        ]);
        $paymentId = (int) $pdo->lastInsertId();

        json_response([
            'success' => true,
            'requires_payment' => true,
            'message' => 'Annonce créée, paiement requis',
            'listing_id' => $id,
            'payment_id' => $paymentId,
            'amount' => (string) $amount,
            'currency' => $currency,
            'status' => 'pending_payment',
        ], 201);
    }

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

    $imagesByListingId = fetch_listing_images($pdo, [$id]);
    $data = map_listing_row($row, $imagesByListingId, [], [], []);
    json_response($data, 201);
}

json_response(['error' => 'Method not allowed'], 405);
