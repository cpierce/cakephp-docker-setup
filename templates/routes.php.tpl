<?php

/**
 * Routes configuration.
 *
 */

use Cake\Routing\Route\DashedRoute;
use Cake\Routing\RouteBuilder;

return static function (RouteBuilder $routes) {
    $routes->setRouteClass(DashedRoute::class);

    $routes->scope('/', function (RouteBuilder $builder) {
        $builder->connect('/', ['controller' => 'Pages', 'action' => 'display', 'home']);
        $builder->connect('/login', [
            'prefix' => 'Admin',
            'controller' => 'Users',
            'action' => 'login'
        ]);
        $builder->connect('/logout', [
            'prefix' => 'Admin',
            'controller' => 'Users',
            'action' => 'logout'
        ]);
        $builder->fallbacks(DashedRoute::class);
    });

    $routes->prefix('Admin', function (RouteBuilder $builder) {
        $builder->setExtensions(['json']);
        $builder->connect('/', 'Homes::index');
        $builder->fallbacks(DashedRoute::class);
    });

};
