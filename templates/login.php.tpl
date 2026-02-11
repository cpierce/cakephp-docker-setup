<div class="container">
    <div class="row justify-content-center mt-5">
        <div class="col-md-6">
            <h4>Admin Area</h4>
            <p>Please log in to continue.</p>
            <?= $this->Form->create(null, [
                'novalidate' => true,
                'id'         => 'login_form',
                'role'       => 'form',
            ]) ?>
            <?= $this->Form->control('email', [
                'required'    => true,
                'autofocus'   => true,
                'placeholder' => 'email@example.com',
            ]) ?>
            <?= $this->Form->control('password', [
                'required' => true,
                'placeholder' => 'secret',
            ]) ?>
            <?= $this->Form->button(__('Login'), [
                'type'  => 'submit',
                'class' => 'btn btn-primary',
            ]) ?>
            <?= $this->Form->end() ?>
        </div>
    </div>
</div>
<?php $this->assign('title', 'Login') ?>
