<?php

	require_once(TOOLKIT . '/class.administrationpage.php');
	require_once(TOOLKIT . '/class.textformattermanager.php');
	require_once(TOOLKIT . '/class.extensionmanager.php');

	Class contentExtensionTemplatedTextFormattersEdit extends AdministrationPage {

		public $formatter;

		private $_driver;

		public function __construct() {
			parent::__construct();

			if ($this->_context[0]) {
				$this->formatter = TextformatterManager::create($this->_context[0]);
			}

			$this->_driver = ExtensionManager::create('templatedtextformatters');
		}

		public function view() {
			Administration::instance()->Page->addScriptToHead(URL . '/extensions/templatedtextformatters/assets/templatedtextformatters.settings.js', 101, false);

			$about = array();
			if ($this->_context[0] && !is_object($this->formatter)) {
				$this->formatter = TextformatterManager::create($this->_context[0]);
			}

			if (is_object($this->formatter)) {
				$about = TextformatterManager::about($this->_context[0]);
			}

			if ($_SESSION['templatedtextformatters-alert']) {
				switch ($_SESSION['templatedtextformatters-alert']) {
					case 'saved':
						$this->pageAlert(
							__(
								'Templated Text Formatter updated at %1$s. <a href="%2$s" accesskey="c">Create another?</a> <a href="%3$s" accesskey="a">View all Templated Text Formatters</a>',
								array(
									DateTimeObj::getTimeAgo(__SYM_TIME_FORMAT__),
									SYMPHONY_URL . '/extension/templatedtextformatters/edit/',
									SYMPHONY_URL . '/extension/templatedtextformatters'
								)
							),
							Alert::SUCCESS);
						break;

					case 'created':
						$this->pageAlert(
							__(
								'Templated Text Formatter created at %1$s. <a href="%2$s" accesskey="c">Create another?</a> <a href="%3$s" accesskey="a">View all Templated Text Formatters</a>',
								array(
									DateTimeObj::getTimeAgo(__SYM_TIME_FORMAT__),
									SYMPHONY_URL . '/extension/templatedtextformatters/edit/',
									SYMPHONY_URL . '/extension/templatedtextformatters'
								)
							),
							Alert::SUCCESS);
						break;
				}
				unset($_SESSION['templatedtextformatters-alert']);
			}

			$fields = $_POST['fields'];

			$this->setPageType('form');
			$this->setTitle(__('%1$s &ndash; %2$s &ndash; %3$s', array(__('Symphony'), __('Templated Text Formatters'), ($fields['name'] ? $fields['name'] : $about['name']))));
			$this->appendSubheading($fields['name'] ? $fields['name'] : ($about['name'] ? $about['name'] : 'Untitled'));
			$this->insertBreadcrumbs(array(
				Widget::Anchor(__('Templated Text Formatters'), SYMPHONY_URL . '/extension/templatedtextformatters'),
			));

			$fieldset = new XMLElement('fieldset');
			$fieldset->setAttribute('class', 'settings');
			$fieldset->appendChild(new XMLElement('legend', __('Essentials')));

			$p = new XMLElement('p', __('WARNING: Name change will disconnect this formatter from any chains and/or fields it may have been added to!'));
			$p->setAttribute('class', 'help');
			$fieldset->appendChild($p);

			$group = new XMLElement('div');
			$group->setAttribute('class', 'two columns');

			$div = new XMLElement('div', NULL, array('class' => 'column'));
			$label = Widget::Label(__('Name'));
			$label->appendChild(Widget::Input('fields[name]', ($fields['name'] ? $fields['name'] : $about['name'])));
			$div->appendChild((isset($this->_errors['name']) ? Widget::wrapFormElementWithError($label, $this->_errors['name']) : $label));

			$group->appendChild($div);

			$div = new XMLElement('div', NULL, array('class' => 'column'));
			$label = Widget::Label(__('Type'));

			$types = $this->_driver->listTypes();
			$options = array();
			if ($about['templatedtextformatters-type']) {
				$options[] = array($about['templatedtextformatters-type'], TRUE, $about['templatedtextformatters-type']);
			}
			else {
				foreach ($types as $t => $info) {
					$options[] = array($t, ($fields['type'] ? $fields['type'] == $t : FALSE), ($info['name'] ? $info['name'] : $t));
				}
			}

			$label->appendChild(Widget::Select('fields[type]', $options, array('id' => 'ds-context')));
			$div->appendChild($label);
			$group->appendChild($div);

			$fieldset->appendChild($group);

			$div = new XMLElement('div');
			$label = Widget::Label(__('Description'));
			$label->appendChild(new XMLElement('i', __('Optional')));
			$label->appendChild(Widget::Input('fields[description]', General::sanitize(isset($fields['description']) ? $fields['description'] : $about['description'])));
			$div->appendChild((isset($this->_errors['description']) ? Widget::wrapFormElementWithError($label, $this->_errors['description']) : $label));
			$fieldset->appendChild($div);

			$this->Form->appendChild($fieldset);


			if (is_object($this->formatter) && method_exists($this->formatter, 'ttf_form')) {
				$fieldset = new XMLElement('fieldset');
				$fieldset->setAttribute('class', 'settings');
				$fieldset->appendChild(new XMLElement('legend', __('Format Options')));

				$this->formatter->ttf_form($fieldset, $this);

				$this->Form->appendChild($fieldset);
			}


			if (is_object($this->formatter)) {
				$fieldset = new XMLElement('fieldset');
				$fieldset->setAttribute('class', 'settings');
				$fieldset->appendChild(new XMLElement('legend', __('Testing grounds')));

				$p = new XMLElement('p', __('Save changes each time you want to see updated output'));
				$p->setAttribute('class', 'help');
				$fieldset->appendChild($p);

				$group = new XMLElement('div');
				$group->setAttribute('class', 'two columns');

				$div = new XMLElement('div', NULL, array('class' => 'column'));
				$label = Widget::Label(__('Test input'));
				$label->appendChild(Widget::Textarea('fields[testin]', 5, 50, $fields['testin']));
				$div->appendChild($label);
				$group->appendChild($div);

				$div = new XMLElement('div', NULL, array('class' => 'column'));
				$label = Widget::Label(__('Test output'));
				$temp = '';
				if ($fields['testin']) $temp = $this->formatter->run($fields['testin']);
				$label->appendChild(Widget::Textarea('fields[testout]', 5, 50, $temp));
				$div->appendChild($label);
				$group->appendChild($div);

				$fieldset->appendChild($group);
				$this->Form->appendChild($fieldset);
			}

			$div = new XMLElement('div');
			$div->setAttribute('class', 'actions');
			$div->appendChild(Widget::Input('action[save]', ($about['handle'] ? __('Save Changes') : __('Create formatter')), 'submit', array('accesskey' => 's')));
			
			if ($about['name']) {
				$button = new XMLElement('button', __('Delete'));
				$button->setAttributeArray(array('name' => 'action[delete]', 'class' => 'confirm delete', 'title' => __('Delete this formatter')));
				$div->appendChild($button);
			}

			$this->Form->appendChild($div);
		}

		public function action() {
			if (array_key_exists('save', $_POST['action'])) $this->save();
			else if (array_key_exists('delete', $_POST['action'])) $this->delete();
		}

		public function save() {
			$about = array();
			if ($this->_context[0] && !is_object($this->formatter)) {
				$this->formatter = TextformatterManager::create($this->_context[0]);
			}

			if (is_object($this->formatter)) {
				$about = TextformatterManager::about($this->_context[0]);
			}

			$fields = $_POST['fields'];
			$driverAbout = ExtensionManager::about('templatedtextformatters');
			$types = $this->_driver->listTypes();

			if (strlen(trim($fields['name'])) < 1) {
				$this->_errors['name'] = __('You have to specify name for text formatter');
				return;
			}

			if ($about['templatedtextformatters-type'] && $about['templatedtextformatters-type'] != $fields['type']) {
				$this->_errors['type'] = __('Changing type of already existing formatter is not allowed');
				return;
			}

			if (!$fields['type'] || !is_array($types[$fields['type']]) || !isset($types[$fields['type']]['path'])) {
				$this->_errors['type'] = __('There is no <code>%s</code> type available', array($fields['type']));
				return;
			}

			$tplfile = $types[$fields['type']]['path'].'/formatter.'.$fields['type'].'.tpl';
			if (!@is_file($tplfile)) {
				$this->_errors['type'] = __('Wrong type of text formatter');
				return;
			}

			$classname = 'ttf_'.Lang::createHandle(trim($fields['name']), NULL, '_', false, true, array('@^[^a-z]+@i' => '', '/[^\w-\.]/i' => ''));
			$file = TEXTFORMATTERS . '/formatter.' . $classname . '.php';

			$isDuplicate = false;
			$queueForDeletion = NULL;

			if (!$about['handle'] && @is_file($file)) $isDuplicate = true;
			else if ($about['handle']) {
				if($classname != $about['handle'] && @is_file($file)) $isDuplicate = true;
				elseif($classname != $about['handle']) $queueForDeletion = TEXTFORMATTERS . '/formatter.' . $about['handle'] . '.php';			
			}

			// Duplicate
			if ($isDuplicate) $this->_errors['name'] = __('Text formatter with the name <code>%s</code> already exists', array($classname));

			if (!empty($this->_errors)) {
				return;
			}

			$description = trim($fields['description']);
			if (empty($description)) {
				$description = __('N/A');
			}

			$author = Symphony::Engine()->Author;

			$tokens = array(
				'___'.$fields['type'].'/* CLASS NAME */' => $classname,
				'/* NAME */' => preg_replace('/[^\w\s\.-_\&\;]/i', '', trim($fields['name'])),
				'/* AUTHOR NAME */' => self::cleanupString($author->getFullName()),
				'/* AUTHOR WEBSITE */' => self::cleanupString(URL),
				'/* AUTHOR EMAIL */' => self::cleanupString($author->get('email')),
				'/* RELEASE DATE */' => DateTimeObj::getGMT('c'), //date('Y-m-d', $oDate->get(true, false)),
				'/* DESCRIPTION */' => self::cleanupString($description),
				'/* TEMPLATEDTEXTFORMATTERS VERSION */' => $driverAbout['version'],
				'/* TEMPLATEDTEXTFORMATTERS TYPE */' => $fields['type'],
			);

			if (!is_object($this->formatter)) {
				include_once($tplfile);
				$temp = 'formatter___'.$fields['type'];
				$temp = new $temp();
				if (method_exists($temp, 'ttf_tokens')) {
					$tokens = array_merge($tokens, $temp->ttf_tokens());
				}
			}
			else if (method_exists($this->formatter, 'ttf_tokens')) {
				$tokens = array_merge($tokens, $this->formatter->ttf_tokens());
			}

			$ttfShell = file_get_contents($tplfile);
			$ttfShell = str_replace(array_keys($tokens), $tokens, $ttfShell);
			$ttfShell = str_replace('/* CLASS NAME */', $classname, $ttfShell);

			// Write the file
			if (!is_writable(dirname($file)) || !$write = General::writeFile($file, $ttfShell, Symphony::Configuration()->get('write_mode', 'file'))) {
				$this->pageAlert(__('Failed to write Text Formatter source to <code>%s</code>. Please check permissions.', array($file)), Alert::ERROR);
			}
			// Write Successful
			else {
				if ($queueForDeletion || !$about['name']) {
					if ($queueForDeletion) General::deleteFile($queueForDeletion);
					
					// TODO: Find a way to make formatted fields update their content
					$_SESSION['templatedtextformatters-alert'] = 'created';
					redirect(URL . '/symphony/extension/templatedtextformatters/edit/'.$classname);
				}
				else {
					// Update current data
					$_SESSION['templatedtextformatters-alert'] = 'saved';
					$_POST['fields']['name'] = $tokens['/* NAME */'];
					$_POST['fields']['description'] = $tokens['/* DESCRIPTION */'];
				}
			}
		}

		public function delete() {
			$file = TEXTFORMATTERS . '/formatter.' . $this->_context[0] . '.php';
			if (!General::deleteFile($file))
				$this->pageAlert(__('Failed to delete <code>%s</code>. Please check permissions.', array($file)), Alert::ERROR);
			else
				redirect(URL . '/symphony/extension/templatedtextformatters/');
		}



		// This prepares string to be ready to put between single quot characters in PHP source code.
		public static function cleanupString($str) {
			return preg_replace('/^\'|\'$/', '', var_export($str, true));
		}

	}

