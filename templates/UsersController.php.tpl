<?php
declare(strict_types=1);

namespace App\Controller\Admin;

use \App\Controller\Admin\AdminController;
use \Cake\Event\EventInterface;

/**
 * User controller.
 *
 * @property \App\Model\Table\UsersTable $Users
 * @property \Authentication\Controller\Component\AuthenticationComponent $Authentication
 */
class UsersController extends AdminController
{

    /**
     * Before Filter method
     *
     * @param EventInterface $event
     * @return void
     */
    public function beforeFilter(EventInterface $event): void
    {
        parent::beforeFilter($event);
        $this->Authentication->addUnauthenticatedActions([
            'login',
        ]);
    }

    /**
     * Login method
     *
     * @return \Cake\Http\Response|null|void
     */
    public function login()
    {
        $this->request->allowMethod([
            'get',
            'post',
        ]);

        $result = $this->Authentication->getResult();
        if ($result && $result->isValid()) {
            /** @var \App\Model\Entity\User|null $entity */
            $entity = $result->getData();
            if ($entity) {
                $this->Users->setLastLogin($entity->id);
            }
            return $this->redirect([
                'prefix'     => 'Admin',
                'controller' => 'Homes',
                'action'     => 'index',
            ]);
        } else {
            if ($this->request->is(['post'])) {
                $this->Flash->error(__('Login Failed'));
            }
        }
    }

    /**
     * Logout method
     *
     * @return \Cake\Http\Response|null|void
     */
    public function logout()
    {
        $result = $this->Authentication->getResult();
        if ($result && $result->isValid()) {
            $this->Authentication->logout();
            return $this->redirect('/');
        }
    }

}
