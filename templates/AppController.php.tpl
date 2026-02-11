<?php

declare(strict_types=1);

namespace App\Controller;

use \Cake\Controller\Controller;
use \Cake\Event\EventInterface;
use \Cake\Http\Response;

/**
 * Application Controller
 *
 * @property \Authentication\Controller\Component\AuthenticationComponent $Authentication
 */
class AppController extends Controller
{
    /**
     * Initialization hook method
     *
     * @return void
     */
    public function initialize(): void
    {
        parent::initialize();

        $this->loadComponent('Flash');
        $this->loadComponent('FormProtection');
        $this->loadComponent('Authentication.Authentication');
    }

    /**
     * Before filter callback method
     *
     * @param EventInterface<Controller> $event
     * @return Response|null|void
     */
    public function beforeFilter(EventInterface $event)
    {
        $prefix = $this->getRequest()->getParam('prefix');
        if ($prefix !== 'Admin') {
            $this->Authentication->addUnauthenticatedActions(['add', 'display', 'index', 'view']);
        }
        $here = $this->getRequest()->getUri()->getPath();
        $this->set(compact('here'));
    }

    /**
     * Before render callback method
     *
     * @param EventInterface<Controller> $event
     * @return Response|null|void
     */
    public function beforeRender(EventInterface $event)
    {
        $user_info = null;
        if ($this->components()->has('Authentication')) {
            $user_check = $this->Authentication->getResult();
            if ($user_check && $user_check->isValid()) {
                $user_info = $user_check->getData();
            }
        }

        $this->set(compact('user_info'));
    }

    /**
     * Index function
     *
     * @return \Cake\Http\Response|null|void
     */
    public function index()
    {
    }
}
