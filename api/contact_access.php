<?php

function ensure_contact_access_payments_table(PDO $pdo): void
{
    static $initialized = false;
    if ($initialized) {
        return;
    }

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS contact_access_payments (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            user_id BIGINT UNSIGNED NOT NULL,
            listing_id BIGINT UNSIGNED NOT NULL,
            provider VARCHAR(50) NOT NULL DEFAULT 'cmi',
            provider_txn_id VARCHAR(191) DEFAULT NULL,
            amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            currency VARCHAR(10) NOT NULL DEFAULT 'MAD',
            status VARCHAR(30) NOT NULL DEFAULT 'pending',
            provider_payload LONGTEXT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            paid_at DATETIME DEFAULT NULL,
            KEY idx_contact_access_user_listing (user_id, listing_id),
            KEY idx_contact_access_listing_user_status (listing_id, user_id, status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $initialized = true;
}

function contact_access_pricing(PDO $pdo): array
{
    $amount = 10.0;
    $currency = 'MAD';

    return [
        'amount' => $amount,
        'currency' => $currency,
    ];
}

function find_contact_access_paid_record(PDO $pdo, int $userId, int $listingId): ?array
{
    ensure_contact_access_payments_table($pdo);

    $stmt = $pdo->prepare("
        SELECT id, user_id, listing_id, amount, currency, status, 'contact_access_payments' AS source
        FROM contact_access_payments
        WHERE user_id = :uid
          AND listing_id = :lid
          AND status = 'paid'
        ORDER BY id DESC
        LIMIT 1
    ");
    $stmt->execute([
        ':uid' => $userId,
        ':lid' => $listingId,
    ]);
    $record = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($record) {
        return $record;
    }

    return find_legacy_contact_access_record($pdo, $userId, $listingId, 'paid');
}

function find_contact_access_pending_record(PDO $pdo, int $userId, int $listingId): ?array
{
    ensure_contact_access_payments_table($pdo);

    $stmt = $pdo->prepare("
        SELECT id, user_id, listing_id, amount, currency, status, 'contact_access_payments' AS source
        FROM contact_access_payments
        WHERE user_id = :uid
          AND listing_id = :lid
          AND status = 'pending'
        ORDER BY id DESC
        LIMIT 1
    ");
    $stmt->execute([
        ':uid' => $userId,
        ':lid' => $listingId,
    ]);
    $record = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($record) {
        return $record;
    }

    return find_legacy_contact_access_record($pdo, $userId, $listingId, 'pending');
}

function create_contact_access_pending_record(
    PDO $pdo,
    int $userId,
    int $listingId,
    float $amount,
    string $currency
): array {
    ensure_contact_access_payments_table($pdo);

    $stmt = $pdo->prepare("
        INSERT INTO contact_access_payments (
            user_id,
            listing_id,
            provider,
            amount,
            currency,
            status,
            created_at
        ) VALUES (
            :user_id,
            :listing_id,
            'cmi',
            :amount,
            :currency,
            'pending',
            NOW()
        )
    ");
    $stmt->execute([
        ':user_id' => $userId,
        ':listing_id' => $listingId,
        ':amount' => $amount,
        ':currency' => $currency,
    ]);

    return [
        'id' => (int) $pdo->lastInsertId(),
        'user_id' => $userId,
        'listing_id' => $listingId,
        'amount' => number_format($amount, 2, '.', ''),
        'currency' => $currency,
        'status' => 'pending',
        'source' => 'contact_access_payments',
    ];
}

function load_contact_access_record_by_id(PDO $pdo, int $recordId, int $listingId): ?array
{
    ensure_contact_access_payments_table($pdo);

    $stmt = $pdo->prepare("
        SELECT id, user_id, listing_id, amount, currency, status, 'contact_access_payments' AS source
        FROM contact_access_payments
        WHERE id = :id
          AND listing_id = :listing_id
        LIMIT 1
    ");
    $stmt->execute([
        ':id' => $recordId,
        ':listing_id' => $listingId,
    ]);
    $record = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($record) {
        return $record;
    }

    try {
        $stmt = $pdo->prepare("
            SELECT id, user_id, listing_id, amount, currency, status, 'payments' AS source
            FROM payments
            WHERE id = :id
              AND listing_id = :listing_id
              AND purpose = 'contact_access'
            LIMIT 1
        ");
        $stmt->execute([
            ':id' => $recordId,
            ':listing_id' => $listingId,
        ]);
        $legacyRecord = $stmt->fetch(PDO::FETCH_ASSOC);
        return $legacyRecord ?: null;
    } catch (Throwable $e) {
        return null;
    }
}

function mark_contact_access_record_paid(
    PDO $pdo,
    array $record,
    string $provider,
    ?string $providerTxnId,
    string $providerPayload
): void {
    $source = (string) ($record['source'] ?? 'contact_access_payments');

    if ($source === 'payments') {
        $stmt = $pdo->prepare("
            UPDATE payments
            SET status = 'paid',
                provider = :provider,
                provider_txn_id = :txn,
                provider_payload = :payload,
                paid_at = NOW()
            WHERE id = :id
        ");
        $stmt->execute([
            ':provider' => $provider,
            ':txn' => $providerTxnId,
            ':payload' => $providerPayload,
            ':id' => (int) $record['id'],
        ]);
        return;
    }

    ensure_contact_access_payments_table($pdo);

    $stmt = $pdo->prepare("
        UPDATE contact_access_payments
        SET status = 'paid',
            provider = :provider,
            provider_txn_id = :txn,
            provider_payload = :payload,
            paid_at = NOW()
        WHERE id = :id
    ");
    $stmt->execute([
        ':provider' => $provider,
        ':txn' => $providerTxnId,
        ':payload' => $providerPayload,
        ':id' => (int) $record['id'],
    ]);
}

function user_has_contact_access(PDO $pdo, int $userId, int $listingId): bool
{
    return find_contact_access_paid_record($pdo, $userId, $listingId) !== null;
}

function find_legacy_contact_access_record(PDO $pdo, int $userId, int $listingId, string $status): ?array
{
    try {
        $stmt = $pdo->prepare("
            SELECT id, user_id, listing_id, amount, currency, status, 'payments' AS source
            FROM payments
            WHERE user_id = :uid
              AND listing_id = :lid
              AND purpose = 'contact_access'
              AND status = :status
            ORDER BY id DESC
            LIMIT 1
        ");
        $stmt->execute([
            ':uid' => $userId,
            ':lid' => $listingId,
            ':status' => $status,
        ]);
        $record = $stmt->fetch(PDO::FETCH_ASSOC);
        return $record ?: null;
    } catch (Throwable $e) {
        return null;
    }
}
