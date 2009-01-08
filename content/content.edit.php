<?php

	require_once(TOOLKIT . '/class.administrationpage.php');
	require_once(TOOLKIT . '/class.textformattermanager.php');

	Class contentExtensionTemplatedTextFormattersEdit extends AdministrationPage{

		public $formatterManager;
		public $formatter;

		private $_driver;

		function __construct(&$parent){
			parent::__construct($parent);

			if (!is_object($this->_Parent->FormatterManager)) {
				$this->_Parent->FormatterManager = new TextformatterManager($this->_Parent);
			}
			if ($this->_context[0]) {
				$this->formatter = $this->_Parent->FormatterManager->create($this->_context[0]);
			}

			$this->_driver = $this->_Parent->ExtensionManager->create('templatedtextformatters');
		}

		function view(){
			$about = array();
			if ($this->_context[0] && !is_object($this->formatter)) {
				$this->formatter = $this->_Parent->FormatterManager->create($this->_context[0]);
			}

			if (is_object($this->formatter)) {
				$about = $this->_Parent->FormatterManager->about($this->_context[0]);
			}

			$fields = $_POST['fields'];

			$this->setPageType('form');
			$this->setTitle('Symphony &ndash; Templated Text Formatters &ndash; '.($fields['name'] ? $fields['name'] : $about['name']));
			$this->appendSubheading($fields['name'] ? $fields['name'] : ($about['name'] ? $about['name'] : 'Untitled'));

			$fieldset = new XMLElement('fieldset');
			$fieldset->setAttribute('class', 'settings');
			$fieldset->appendChild(new XMLElement('legend', 'Essentials'));

			$div = new XMLElement('div');
			$div->setAttribute('class', 'group');

			$label = Widget::Label('Name');		
			$label->appendChild(Widget::Input('fields[name]', ($fields['name'] ? $fields['name'] : $about['name'])));
			$div->appendChild((isset($this->_errors['name']) ? $this->wrapFormElementWithError($label, $this->_errors['name']) : $label));

			$label = Widget::Label('Type');

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

			$label->appendChild(Widget::Select('fields[type]', $options, array('id' => 'context')));
			$div->appendChild($label);

			$fieldset->appendChild($div);

			if (is_object($this->formatter) && method_exists($this->formatter, 'ttf_form')) {
				$this->formatter->ttf_form($fieldset, $this);
			}

			$this->Form->appendChild($fieldset);

			if (is_object($this->formatter)) {
				$fieldset = new XMLElement('fieldset');
				$fieldset->setAttribute('class', 'settings');
				$fieldset->appendChild(new XMLElement('legend', 'Testing grounds'));

				$p = new XMLElement('p', 'For now, You have to save changes each time You want to see updated output');
				$p->setAttribute('class', 'help');
				$fieldset->appendChild($p);

				$div = new XMLElement('div');
				$div->setAttribute('class', 'group');

				$label = Widget::Label('Test input');
				$label->appendChild(Widget::Textarea('fields[testin]', 5, 50, $fields['testin']));
				$div->appendChild($label);

				$label = Widget::Label('Test output');
				$temp = '';
				if ($fields['testin']) $temp = $this->formatter->run($fields['testin']);
				$label->appendChild(Widget::Textarea('fields[testout]', 5, 50, $temp));
				$div->appendChild($label);

				$fieldset->appendChild($div);
				$this->Form->appendChild($fieldset);
			}

			$div = new XMLElement('div');
			$div->setAttribute('class', 'actions');
			$div->appendChild(Widget::Input('action[save]', ($about['handle'] ? 'Save Changes' : 'Create formatter'), 'submit', array('accesskey' => 's')));
			
			if($about['name']){
				$button = new XMLElement('button', 'Delete');
				$button->setAttributeArray(array('name' => 'action[delete]', 'class' => 'confirm delete', 'title' => 'Delete this formatter'));
				$div->appendChild($button);
			}

			$this->Form->appendChild($div);
		}

		function action() {
			if (array_key_exists('save', $_POST['action'])) $this->save();
			else if (array_key_exists('delete', $_POST['action'])) $this->delete();
		}

		function save() {
			$about = array();
			if ($this->_context[0] && !is_object($this->formatter)) {
				$this->formatter = $this->_Parent->FormatterManager->create($this->_context[0]);
			}

			if (is_object($this->formatter)) {
				$about = $this->_Parent->FormatterManager->about($this->_context[0]);
			}

			$fields = $_POST['fields'];
			$driverAbout = $this->_driver->about();
			$types = $this->_driver->listTypes();

			if (strlen(trim($fields['name'])) < 1) {
				$this->_errors['name'] = 'You have to specify name for text formatter';
				return;
			}

			if ($about['templatedtextformatters-type'] && $about['templatedtextformatters-type'] != $fields['type']) {
				$this->_errors['type'] = 'Changing type of already existing formatter is not allowed';
				return;
			}

			if (!$fields['type'] || !is_array($types[$fields['type']]) || !isset($types[$fields['type']]['path'])) {
				$this->_errors['type'] = 'There is no '.$fields['type'].' type available';
				return;
			}

			$tplfile = $types[$fields['type']]['path'].'/formatter.'.$fields['type'].'.tpl';
			if (!@is_file($tplfile)) {
				$this->_errors['type'] = 'Wrong type of text formatter';
				return;
			}

			$classname = 'ttf_'.Lang::createHandle(trim($fields['name']), NULL, '_', false, true, array('@^[^a-z]+@i' => '', '/[^\w-\.]/i' => ''));
			$file = TEXTFORMATTERS . '/formatter.' . $classname . '.php';

			$isDuplicate = false;
			$queueForDeletion = NULL;

			if(!$about['handle'] && @is_file($file)) $isDuplicate = true;
			elseif($about['handle']){
				if($classname != $about['handle'] && @is_file($file)) $isDuplicate = true;
				elseif($classname != $about['handle']) $queueForDeletion = TEXTFORMATTERS . '/formatter.' . $about['handle'] . '.php';			
			}

			##Duplicate
			if($isDuplicate) $this->_errors['name'] = 'Text formatter with the name <code>'.$classname.'</code> already exists';

			if(!empty($this->_errors)){
				return;
			}

			$tokens = array(
				'/* CLASS NAME */' => $classname,
				'/* NAME */' => preg_replace('/[^\w\s\.-_\&\;]/i', '', trim($fields['name'])),
				'/* AUTHOR NAME */' => $this->_Parent->Author->getFullName(),
				'/* AUTHOR WEBSITE */' => URL,
				'/* AUTHOR EMAIL */' => $this->_Parent->Author->get('email'),
				'/* RELEASE DATE */' => DateTimeObj::getGMT('c'), //date('Y-m-d', $oDate->get(true, false)),
				'/* TEMPLATEDTEXTFORMATTERS VERSION */' => $driverAbout['version'],
				'/* TEMPLATEDTEXTFORMATTERS TYPE */' => $fields['type'],
			);

			if (is_object($this->formatter) && method_exists($this->formatter, 'ttf_tokens')) {
				$tokens = array_merge($tokens, $this->formatter->ttf_tokens());
			}

			$ttfShell = file_get_contents($tplfile);
			$ttfShell = str_replace(array_keys($tokens), $tokens, $ttfShell);

			##Write the file
			if(!is_writable(dirname($file)) || !$write = General::writeFile($file, $ttfShell, $this->_Parent->Configuration->get('write_mode', 'file')))
				$this->pageAlert('Failed to write Text Formatter source to <code>'.TEXTFORMATTERS.'</code>. Please check permissions.', AdministrationPage::PAGE_ALERT_ERROR);
			##Write Successful
			else{
				if($queueForDeletion || !$about['name']){
					if ($queueForDeletion) General::deleteFile($queueForDeletion);
					
					### TODO: Find a way to make formatted fields update their content

					redirect(URL . '/symphony/extension/templatedtextformatters/edit/'.$classname.'/'.($about['name'] ? 'saved' : 'created').'/');
				}
				else {
					// Update current data
					$_POST['fields']['name'] = $tokens['/* NAME */'];
				}
			}
		}

		function delete() {
			if(!General::deleteFile(TEXTFORMATTERS . '/formatter.' . $this->_context[0] . '.php'))
				$this->pageAlert('Failed to delete <code>'.$this->_context[0].'</code>. Please check permissions.', AdministrationPage::PAGE_ALERT_ERROR);
			else
				redirect(URL . '/symphony/extension/templatedtextformatters/');
		}

	}

?>