angular.module('app-factory').config(['$urlRouterProvider', '$stateProvider', ($urlRouterProvider, $stateProvider) ->

	$urlRouterProvider.otherwise '/account'

	$stateProvider

		#####################################################################
		# USER
		#####################################################################

		.state 'login',
			url: '/login'
			controller: 'LoginCtrl'
			templateUrl: 'client/templates/login.template.html'

		.state 'register',
			url: '/register'
			controller: 'RegisterCtrl'
			templateUrl: 'client/templates/register.template.html'

		.state 'account',
			url: '/account'
			controller: 'AccountCtrl'
			templateUrl: 'client/templates/account.template.html'
			resolve:
				'currentUser': ['$meteor', ($meteor) ->
					return $meteor.requireUser()
				]

		#####################################################################
		# FACTORY
		#####################################################################

		.state 'factory',
			url: '/factory/:application_id/:environment_id'
			abstract: true
			templateUrl: 'client/templates/factory.template.html'
			controller: 'FactoryCtrl'
			resolve:
				'currentUser': ['$meteor', ($meteor) ->
					return $meteor.requireUser()
				]
				'application': ['$meteor', '$q', '$stateParams', ($meteor, $q, $stateParams) -> 
					deferred = $q.defer()
					application_id = $stateParams.application_id
					$meteor.subscribe('Application', application_id).then ->
						application = Application.db.findOne(application_id)
						deferred.resolve(application) if application?
						deferred.reject('Application could not be found') unless application?
					return deferred.promise
				]
				'environment': ['$meteor', '$q', '$stateParams', ($meteor, $q, $stateParams) -> 
					deferred = $q.defer()
					environment_id = $stateParams.environment_id
					$meteor.subscribe('Environment', {environment_id}).then ->
						environment = Environment.db.findOne(environment_id)
						deferred.resolve(environment) if environment?
						deferred.reject('Environment could not be found') unless environment?
					return deferred.promise
				]
				'blueprint': ['$meteor', '$q', 'environment', ($meteor, $q, environment) -> 
					deferred = $q.defer()
					blueprint_id = environment['blueprint_id']
					$meteor.subscribe('Blueprint', {blueprint_id}).then ->
						blueprint = Blueprint.db.findOne(blueprint_id)
						deferred.resolve(blueprint) if blueprint?
						deferred.reject('Blueprint could not be found') unless blueprint?
					return deferred.promise
				]

		.state 'factory.dashboard',
			url: '/dashboard'
			templateUrl: 'client/templates/factory-dashboard.template.html'

		.state 'factory.document',
			url: '/document/:document_schema_id',
			templateUrl: 'client/templates/document-schema.template.html'
			controller: 'DocumentSchemaCtrl',
			resolve: 
				'documentSchema': ['$meteor', '$q', '$stateParams', ($meteor, $q, $stateParams) -> 
					deferred = $q.defer()
					document_schema_id = $stateParams.document_schema_id
					$meteor.subscribe('DocumentSchema', {document_schema_id}).then ->
						documentSchema = DocumentSchema.db.findOne(document_schema_id)
						deferred.resolve(documentSchema) if documentSchema?
						deferred.reject('Document could not be found') unless documentSchema?
					return deferred.promise
				]

		.state 'factory.view',
			url: '/view/:view_id',
			templateUrl: 'client/templates/view.template.html'
			controller: 'ViewCtrl',
			resolve: 
				'view': ['$meteor', '$q', '$stateParams', ($meteor, $q, $stateParams) -> 
					deferred = $q.defer()
					view_id = $stateParams.view_id
					$meteor.subscribe('View', {view_id}).then ->
						view = View.db.findOne(view_id)
						deferred.resolve(view) if view?
						deferred.reject('View could not be found') unless view?
					return deferred.promise
				]

		.state 'factory.layout',
			url: '/layout'
			templateUrl: 'client/templates/factory-layout.template.html'

		.state 'factory.users',
			url: '/users'
			templateUrl: 'client/templates/factory-users.template.html'

		.state 'factory.settings',
			url: '/settings'
			templateUrl: 'client/templates/factory-settings.template.html'
])