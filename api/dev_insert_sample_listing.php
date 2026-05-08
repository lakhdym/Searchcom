<?php
// api/dev_insert_sample_listing.php
// Script de test pour insérer UNE annonce exemple dans la table `listings`.
// À utiliser uniquement en développement.

require_once __DIR__ . '/config.php';

try {
    $pdo = get_pdo();

    // Vérifier s'il existe au moins un utilisateur ; sinon en créer un de test.
    $userId = null;
    $stmtUser = $pdo->query('SELECT id FROM users ORDER BY id ASC LIMIT 1');
    $rowUser = $stmtUser->fetch();
    if ($rowUser && isset($rowUser['id'])) {
        $userId = (int) $rowUser['id'];
    } else {
        // Créer un utilisateur de test minimal
        $now = date('Y-m-d H:i:s');
        $stmtInsertUser = $pdo->prepare("
            INSERT INTO users (role, full_name, email, password_hash, preferred_lang, created_at, updated_at)
            VALUES ('user', :full_name, :email, NULL, 'fr', :created_at, :created_at)
        ");
        $testEmail = 'testuser+' . uniqid() . '@example.com';
        $stmtInsertUser->execute([
            ':full_name' => 'Utilisateur Test',
            ':email' => $testEmail,
            ':created_at' => $now,
        ]);
        $userId = (int) $pdo->lastInsertId();
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
        ':type' => 'found', // exemple : objet trouvé
        ':status' => 'published',
        ':title' => 'Test API – Portefeuille trouvé',
        ':description' => 'Annonce de test insérée automatiquement par dev_insert_sample_listing.php',
        ':city' => 'Casablanca',
        ':location_text' => 'Casablanca, Centre-ville',
        ':created_at' => $now,
    ]);

    $id = (int) $pdo->lastInsertId();

    $stmt = $pdo->prepare("
        SELECT id, type, status, title, description, city, location_text, is_boosted, created_at
        FROM listings
        WHERE id = :id
    ");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();

    if (!$row) {
        json_response(['success' => false, 'message' => 'Insertion effectuée mais impossible de relire la ligne'], 500);
    }

    // Réutilise le helper de annonces.php si présent, sinon renvoie brut
    $response = [
        'success' => true,
        'message' => 'Annonce de test insérée avec succès.',
        'listing' => $row,
    ];

    json_response($response);
} catch (Throwable $e) {
    json_response([
        'success' => false,
        'message' => 'Erreur lors de l\'insertion de la liste de test.',
        'error' => $e->getMessage(),
    ], 500);
}

