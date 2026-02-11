<?php
/*
 * Local configuration file to provide any overrides to your app.php configuration.
 * Copy and save this file as app_local.php and make changes as required.
 * Note: It is not recommended to commit files with credentials such as app_local.php
 * into source code version control.
 */
return [
    'debug' => filter_var(env('DEBUG', false), FILTER_VALIDATE_BOOLEAN),

    'Security' => [
        'salt' => env('SECURITY_SALT', '__SALT__'),
    ],

    'Datasources' => [
        'default' => [
            'host' => '{{DB_HOST}}',
            'username' => '{{DB_USERNAME}}',
            'password' => '{{DB_PASSWORD}}',
            'database' => '{{DB_DATABASE}}',
            'url' => env('DATABASE_URL', null),
        ],

        'test' => [
            'host' => null,
            'username' => null,
            'password' => null,
            'database' => null,
            'url' => env('DATABASE_TEST_URL', null),
        ],
    ],

    'EmailTransport' => [
        'default' => [
            'className' => 'Smtp',
            'host' => 'email-smtp.us-east-1.amazonaws.com',
            'port' => 587,
            'username' => '{{SES_USERNAME}}',
            'password' => '{{SES_PASSWORD}}',
            'tls' => true,
        ],
    ],
    'Email' => [
        'default' => [
            'transport' => 'default',
            'from' => ['no-reply@{{DOMAIN}}' => '{{DOMAIN}}'],
        ],
    ],
];
