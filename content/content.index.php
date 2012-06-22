<?php

	require_once(TOOLKIT . '/class.administrationpage.php');
	require_once(TOOLKIT . '/class.textformattermanager.php');
	require_once(TOOLKIT . '/class.extensionmanager.php');

	Class contentExtensionTemplatedTextFormattersIndex extends AdministrationPage {

		private $_driver;

		public function __construct() {
			parent::__construct();

			$this->setTitle(__('%1$s &ndash; %2$s', array(__('Symphony'), __('Templated Text Formatters'))));

			$this->_driver = ExtensionManager::create('templatedtextformatters');
		}

		public function view() {
			$this->setPageType('table');
			$this->appendSubheading(__('Templated Text Formatters'), Widget::Anchor(__('Create New'), URL.'/symphony/extension/templatedtextformatters/edit/', __('Create new formatter'), 'create button'));

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
				foreach ($formatters as $id => $data) {
					$formatter = TextformatterManager::create($id);
					$about = $formatter->about();

					$td1 = Widget::TableData(Widget::Anchor($about['name'], URL."/symphony/extension/templatedtextformatters/edit/{$id}/", $about['name']));
					$td2 = Widget::TableData($about['templatedtextformatters-type']);
					$td3 = Widget::TableData(General::sanitize($about['description']));

					$td1->appendChild(Widget::Input('items['.$id.']', NULL, 'checkbox'));

					// Add a row to the body array, assigning each cell to the row
					$aTableBody[] = Widget::TableRow(array($td1, $td2, $td3));
				}
			}

			$table = Widget::Table(Widget::TableHead($aTableHead), NULL, Widget::TableBody($aTableBody), 'selectable');
			$this->Form->appendChild($table);

			$div = new XMLElement('div');
			$div->setAttribute('class', 'actions');

			$options = array(
				array(NULL, false, __('With Selected...')),
				array('delete', false, __('Delete'), 'confirm', null, array(
					'data-message' => __('Are you sure you want to delete the selected text formatters?')
				))
			);

			$div->appendChild(Widget::Apply($options));

			$this->Form->appendChild($div);
		}

		public function action() {
			if (!isset($_POST['action']['apply']) || !isset($_POST['with-selected'])) return;
			if ($_POST['with-selected'] == 'delete' && is_array($_POST['items'])) {
				foreach ($_POST['items'] as $id => $selected) {
					$this->delete($id);
				}
				redirect(URL . '/symphony/extension/templatedtextformatters/');
			}
		}

		public function delete($id) {
			$file = TEXTFORMATTERS . '/formatter.' . $id . '.php';
			if (!General::deleteFile($file))
				$this->pageAlert(__('Failed to delete <code>%s</code>. Please check permissions.', array($file)), Alert::ERROR);
		}
	}

