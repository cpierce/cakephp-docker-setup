<?php

declare(strict_types=1);

namespace App\Controller\Admin;

use \App\Controller\AppController;
use \Cake\Utility\Inflector;
use \Cake\Http\Exception\NotFoundException;
use \Cake\Event\EventInterface;

/**
 * Admin Controller
 *
 */
class AdminController extends AppController
{
    /**
     * Initialization hook method
     *
     * @return void
     */
    public function initialize(): void
    {
        parent::initialize();
        $this->FormProtection->setConfig('unlockedFields', ['search_terms']);
    }

    /**
     * Before Filter method
     *
     * @param \Cake\Event\EventInterface $event
     */
    public function beforeFilter(EventInterface $event)
    {
        $this->set('here', 'admin');
        $this->viewBuilder()->setVar('noindex', true);
    }

    /**
     * Admin index method
     *
     * @return \Cake\Http\Response|null|void
     */
    public function index()
    {
        if (isset($this->defaultTable) && !empty($this->defaultTable)) {
            $table = $this->fetchTable($this->defaultTable);
            $query = $table->find();
            if ($table->hasField('deleted_by')) {
                $query->where([
                    $this->defaultTable . '.deleted_by' => 0,
                ]);
            }
            $data = $this->paginate($query);
            $this->set(Inflector::tableize($this->defaultTable), $data);
        }
    }

    /**
     * Admin add method
     *
     * @return \Cake\Http\Response|null|void Redirects on successful add, renders view otherwise.
     */
    public function add()
    {
        if (isset($this->defaultTable) && !empty($this->defaultTable)) {
            $table = $this->fetchTable($this->defaultTable);
            $data  = $table->newEmptyEntity();
            $name  = Inflector::singularize(Inflector::humanize(Inflector::underscore($this->defaultTable)));

            if ($this->request->is(['post', 'put'])) {
                $entity_data = $this->request->getData();
                if ($table->hasField('entered_by')) {
                    $authentication = $this->Authentication->getIdentity();
                    if ($authentication && isset($authentication->id)) {
                        $entity_data['entered_by'] = $authentication->id;
                    }
                }
                $data = $table->patchEntity($data, $entity_data);
                if ($table->save($data)) {
                    $this->Flash->success(__('The ' . $name . ' has been saved.'));

                    return $this->redirect(['action' => 'index']);
                }
                $this->Flash->error(__('Unable to add the ' . $name . '.'));
            }
            $this->set(compact('data'));
        }
    }

    /**
     * Admin edit method
     *
     * @param int|null $data_id.
     *
     * @return \Cake\Http\Response|null|void Redirects on successful edit, renders view otherwise.
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When record not found.
     */
    public function edit($data_id = null)
    {
        if (isset($this->defaultTable) && !empty($this->defaultTable)) {
            $name = Inflector::singularize(Inflector::humanize(Inflector::underscore($this->defaultTable)));

            if (!$data_id) {
                throw new NotFoundException(__('Invalid ' . $name . ' ID.'));
            }

            $table = $this->fetchTable($this->defaultTable);
            $data  = $table->get($data_id, [
                'contain' => [],
            ]);
            if ($this->request->is(['patch', 'post', 'put'])) {
                $data = $table->patchEntity($data, $this->request->getData());
                if ($table->save($data)) {
                    $this->Flash->success(__('The ' . $name . ' has been updated.'));
                    return $this->redirect([
                        'action' => 'index',
                    ]);
                }
                $this->Flash->error(__('Unable to update ' . $name . '.'));
            }

            $this->set(compact('data'));
        }
    }

    /**
     * Admin delete method
     *
     * @param int|null $data_id
     *
     * @return \Cake\Http\Response|null|void Redirects to index.
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When record not found.
     */
    public function delete($data_id = null)
    {
        if (isset($this->defaultTable) && !empty($this->defaultTable)) {
            $name = Inflector::singularize(Inflector::humanize(Inflector::underscore($this->defaultTable)));

            if (!$data_id) {
                throw new NotFoundException(__('Invalid ' . $name . ' ID.'));
            }

            $this->request->allowMethod(['post', 'delete']);

            $table = $this->fetchTable($this->defaultTable);
            $data  = $table->get($data_id);

            if ($table->getSchema()->hasColumn('deleted_by')) {
                $authentication = $this->Authentication->getIdentity();
                if ($authentication && isset($authentication->id) && isset($data->deleted_by)) {
                    $data->deleted_by = $authentication->id;

                    if ($table->save($data)) {
                        $this->Flash->success(__('The ' . $name . ' has been deactivated.'));
                        return $this->redirect(['action' => 'index']);
                    }

                    $this->Flash->error(__('The ' . $name . ' could not be deactivated. Please, try again.'));
                }
            } else {
                if ($table->delete($data)) {
                    $this->Flash->success(__('The ' . $name . ' has been deleted.'));
                } else {
                    $this->Flash->error(__('The ' . $name . ' could not be deleted. Please, try again.'));
                }
            }
        }
        return $this->redirect(['action' => 'index']);
    }

    /**
     * Builds a tree list from the nodes
     *
     * @param array<mixed> $nodes
     * @param string $prefix
     * @return array<mixed>
     */
    protected function buildTreeList(array $nodes, string $prefix = ''): array
    {
        $list = [];
        foreach ($nodes as $node) {
            $label = $prefix . $node->display_name;
            $list[$node->id] = $label;

            if (!empty($node->children)) {
                $list += $this->buildTreeList($node->children, $label . ' - ');
            }
        }
        return $list;
    }
}
