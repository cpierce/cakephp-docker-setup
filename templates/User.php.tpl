<?php

declare(strict_types=1);

namespace App\Model\Entity;

use Authentication\PasswordHasher\DefaultPasswordHasher;
use Cake\ORM\Entity;

/**
 * User Entity
 *
 * @property int $id
 * @property string|null $first_name
 * @property string|null $last_name
 * @property string|null $email
 * @property string|null $password
 * @property int|null $user_type
 * @property \Cake\I18n\DateTime|null $last_login
 * @property int $deleted_by
 * @property \Cake\I18n\DateTime|null $created
 * @property \Cake\I18n\DateTime|null $modified
 */
class User extends Entity
{
    /**
     * Fields that can be mass assigned using newEntity() or patchEntity().
     *
     * @var array<string, bool>
     */
    protected array $_accessible = [
        'first_name' => true,
        'last_name' => true,
        'email' => true,
        'password' => true,
        'user_type' => true,
        'last_login' => true,
        'deleted_by' => true,
        'created' => true,
        'modified' => true,
    ];

    /**
     * Set Password method
     *
     * @param string $password
     * @return string|null
     */
    protected function _setPassword(string $password) : ?string
    {
        if (strlen($password) > 0) {
            return (new DefaultPasswordHasher())->hash($password);
        }
        return null;
    }

    /**
     * Get Full Name method
     *
     * @return string
     */
    public function _getFullName(): string
    {
        $firstName = $this->first_name ?? '';
        $lastName = $this->last_name ?? '';
        return trim("{$firstName} {$lastName}");
    }

    /**
     * Get Initials method
     *
     * @return string
     */
    public function _getInitials(): string
    {
        $firstName = $this->first_name ?? '';
        $lastName = $this->last_name ?? '';
        return strtoupper(substr($firstName, 0, 1) . substr($lastName, 0, 1));
    }
}
