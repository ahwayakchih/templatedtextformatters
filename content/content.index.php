<?php

	require_once(TOOLKIT . '/class.administrationpage.php');
	require_once(TOOLKIT . '/class.textformattermanager.php');

	Class contentExtensionTemplatedTextFormattersIndex extends AdministrationPage {

		private $_driver;

		function __construct(&$parent) {
			parent::__construct($parent);

			$this->setTitle(__('%1$s &ndash; %2$s', array(__('Symphony'), __('Templated Text Formatters'))));

			$this->_driver = $this->_Parent->ExtensionManager->create('templatedtextformatters');
		}

		function view() {
			$this->setPageType('table');
			$this->appendSubheading(__('Templated Text Formatters'), Widget::Anchor(__('Create New'), '/symphony/extension/templatedtextformatters/edit/', __('Create a new hub'), 'create button'));

			$aTableHead = array(
				array(__('Title'), 'col'),
				array(__('Type'), 'col'),
				array(__('Description'), 'col')
			);	

			$aTableBody = array();

			$formatters = $this->_driver->listAll();
			if (!is_array($formatters) || empty($formatters)) {
				$aTableBody = array(Widget::TableRow(array(Widget::TableData(__('None found.'), 'inactive', NULL, count($aTableHead)))));
			}
			else {
				$tfm = new TextformatterManager($this->_Parent);
				foreach ($formatters as $id => $data) {
					$formatter = $tfm->create($id);
					$about = $formatter->about();

					$td1 = Widget::TableData(Widget::Anchor($about['name'], URL."/symphony/extension/templatedtextformatters/edit/{$id}/", $about['name']));
					$td2 = Widget::TableData($about['templatedtextformatters-type']);
					$td3 = Widget::TableData($about['description']);

					$td1->appendChild(Widget::Input('items['.$id.']', NULL, 'checkbox'));

					// Add a row to the body array, assigning each cell to the row
					$aTableBody[] = Widget::TableRow(array($td1, $td2, $td3));
				}
			}

			$table = Widget::Table(Widget::TableHead($aTableHead), NULL, Widget::TableBody($aTableBody));
			$this->Form->appendChild($table);

			$div = new XMLElement('div');
			$div->setAttribute('class', 'actions');

			$options = array(
				array(NULL, false, __('With Selected...')),
				array('delete', false, __('Delete'))
			);

			$div->appendChild(Widget::Select('with-selected', $options));
			$div->appendChild(Widget::Input('action[apply]', __('Apply'), 'submit'));

			$this->Form->appendChild($div);
		}

		function action() {
			if (!$_POST['action']['apply']) return;
			if ($_POST['with-selected'] == 'delete' && is_array($_POST['items'])) {
				foreach ($_POST['items'] as $id => $selected) {
					$this->delete($id);
				}
				redirect(URL . '/symphony/extension/templatedtextformatters/');
			}
		}

		function delete($id) {
			$file = TEXTFORMATTERS . '/formatter.' . $id . '.php';
			if (!General::deleteFile($file))
				$this->pageAlert(__('Failed to delete <code>%s</code>. Please check permissions.', array($file)), Alert::ERROR);
		}
	}

