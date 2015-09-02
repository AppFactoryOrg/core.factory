angular.module('app-factory').directive('afAppWidgetTable', ['$rootScope', '$modal', '$meteor', '$timeout', 'toaster', 'EditDocumentModal', 'ViewDocumentModal', ($rootScope, $modal, $meteor, $timeout, toaster, EditDocumentModal, ViewDocumentModal) ->
	restrict: 'E'
	templateUrl: 'client/components/app/app-widget-table.template.html'
	replace: true
	scope:
		'widget': 			'='
		'view':				'='
	controller: ['$scope', ($scope) ->

		$scope.INITIAL_LIMIT = 20
		$scope.LOADING_TIMEOUT = 3000

		$scope.limit = $scope.INITIAL_LIMIT

		$scope.lastLimit = null
		$scope.lastSort = null
		$scope.lastFilter = null

		$scope.loading = false
		$scope.error = false
		$scope.errorMessage = ''
		$scope.loadingStartedAt = null
		$scope.shouldShowLoadingTimeout = false

		$scope.sortableOptions =
			orderChanged: -> $scope.collectionWasReordered()

		$scope.documents = []

		$scope.shouldShowName = ->
			return true if $scope.widget['configuration']['show_name']
			return false

		$scope.shouldShowLimitsIndicator = ->
			return false unless $scope.view?
			return true if not _.isEmpty($scope.view['limits'])
			return false

		$scope.shouldShowFilterOptions = ->
			return false if $scope.allAttributes?.length is 0
			return true if $scope.widget['configuration']['show_filter_options']
			return false

		$scope.shouldShowSortOptions = ->
			return false if $scope.sortOptions?.length is 0
			return true if $scope.widget['configuration']['show_sort_options']
			return false

		$scope.shouldShowCreateButton = ->
			return true if $scope.widget['configuration']['show_create_button']
			return false

		$scope.shouldShowEditButtons = ->
			return true if $scope.widget['configuration']['show_edit_buttons']
			return false

		$scope.shouldShowSelectButton = ->
			return true if $scope.widget['configuration']['show_select_button']
			return false

		$scope.shouldAllowReordering = ->
			return true if $scope.widget['configuration']['allow_reordering']
			return false

		$scope.shouldShowMoreLink = ->
			return false if $scope.loading
			return false unless $scope.documents?
			return false if $scope.documents.length < $scope.limit
			return false if $scope.documents.length >= Config['MAX_TABLE_RECORDS']
			return true

		$scope.shouldShowTooMuchDataWarning = ->
			return false if $scope.loading
			return true if $scope.documents.length >= Config['MAX_TABLE_RECORDS']
			return false

		$scope.hasActiveFilter = ->
			return true if not _.isEmpty($scope.filter)
			return false

		$scope.hasActiveSort = ->
			return true if not _.isEqual($scope.sort, {'created_on': -1})
			return false

		$scope.toggleLimitsIndicatorPanel = ->
			$scope.$broadcast('TOGGLE_LIMITS_PANEL')

		$scope.toggleSortPanel = ->
			$scope.$broadcast('TOGGLE_SORT_PANEL')

		$scope.toggleFilterPanel = ->
			$scope.$broadcast('TOGGLE_FILTER_PANEL')

		$scope.addDocument = ->
			documentSchema = $scope.documentSchema
			modal = $modal.open(new EditDocumentModal({documentSchema}))
			modal.result.then (document) ->
				$meteor.call('Document.create', document)
					.catch (error) ->
						console.error(error)
						toaster.pop(
							type: 'error'
							body: "Could not create document: #{error.reason}"
							showCloseButton: true
						)

		$scope.viewDocument = (document) ->
			documentSchema = $scope.documentSchema
			$modal.open(new ViewDocumentModal({document, documentSchema}))

		$scope.editDocument = (document) ->
			documentSchema = $scope.documentSchema
			modal = $modal.open(new EditDocumentModal({document, documentSchema}))
			modal.result.then (document) ->
				$meteor.call('Document.update', document)
					.catch (error) ->
						console.error(error)
						toaster.pop(
							type: 'error'
							body: "Could not update document: #{error.reason}"
							showCloseButton: true
						)

		$scope.deleteDocument = (document) ->
			return unless confirm('Are you sure you want to delete this record? This action cannot be undone.')
			$meteor.call('Document.delete', document['_id'])

		$scope.executeAction = (action, document) ->
			routine_id = action['routine_id']
			environment_id = document['environment_id']
			inputs = [{
				name: 'Document'
				value: document
			}]
			$meteor.call('Routine.execute', {routine_id, inputs, environment_id})
				.finally ->
					$scope.isLoading = false
				.catch (error) ->
					console.error(error)
					toaster.pop(
						type: 'error'
						body: "#{error.reason}"
						showCloseButton: true
					)

		$scope.selectDocument = (document) ->
			$scope.$emit('DOCUMENT_SELECTED', document)

		$scope.loadMore = ->
			$scope.limit += 20 unless $scope.limit >= Config['MAX_TABLE_RECORDS']

		$scope.retry = ->
			switch $scope.widget['configuration']['data_source']['type']
				when ScreenWidget.DATA_SOURCE_TYPE['Database'].value
					$scope.loading = false
					if $scope.limit is $scope.INITIAL_LIMIT
						$scope.limit = $scope.INITIAL_LIMIT+1
					else
						$scope.limit = $scope.INITIAL_LIMIT

		$scope.collectionWasReordered = ->
			console.warn 'refreshing collection'
			_.remove($scope.collection)
			newCollection = _.pluck($scope.documents, '_id')
			newCollection.forEach (id) ->
				$scope.collection.push(id)

		# Initialize
		dataSource = $scope.widget['configuration']['data_source']
		$scope.documentSchema = DocumentSchema.db.findOne(dataSource['document_schema_id'])
		$scope.sortOptions = DocumentSchema.getSortOptions($scope.documentSchema)
		$scope.allAttributes = DocumentSchema.getAllAttributes($scope.documentSchema)

		if $scope.view?
			if $scope.view['filter']?
				$scope.filter = _.cloneDeep($scope.view['filter'])
			else
				$scope.filter = {}

			if $scope.view['sort']? and not _.isEmpty($scope.view['sort'])
				$scope.sort = _.cloneDeep($scope.view['sort'])
			else
				$scope.sort = {'created_on': -1}

		if $scope.widget['configuration']['attributes']?
			$scope.attributes = []
			$scope.widget['configuration']['attributes'].forEach (attribute_id) ->
				attribute = _.findWhere($scope.allAttributes, {'id': attribute_id})
				return unless attribute?
				$scope.attributes.push(attribute)
		else
			$scope.attributes = $scope.allAttributes

		switch dataSource['type']
			when ScreenWidget.DATA_SOURCE_TYPE['Database'].value
				$meteor.autorun($scope, ->
					limit = $scope.getReactively('limit')
					sort = $scope.getReactively('sort')
					filter = $scope.getReactively('filter')

					paging = {limit, sort}
					filter = _.assign(_.cloneDeep(filter), {
						'environment_id': $rootScope.environment['_id']
						'document_schema_id': $scope.documentSchema['_id']
					})

					if $scope.view? and not _.isEmpty($scope.view['limits'])
						filter['$and'] = $scope.view['limits']

					unless _.isEqual(limit, $scope.lastLimit) and _.isEqual(sort, $scope.lastSort) and _.isEqual(filter, $scope.lastFilter)
						startedAt = Date.now()
						$scope.loading = true
						$scope.loadingStartedAt = startedAt
						$scope.shouldShowLoadingTimeout = false
						$timeout(->
							if $scope.loading is true and $scope.loadingStartedAt is startedAt
								$scope.shouldShowLoadingTimeout = true
						, $scope.LOADING_TIMEOUT)

					$scope.$meteorSubscribe('Documents', filter, paging)
						.then ->
							$scope.documents = $scope.$meteorCollection -> Document.db.find(filter, paging)
						.catch (error) ->
							$scope.error = true
							$scope.errorMessage = error.reason
							console.error(error)
						.finally ->
							$scope.loading = false

					$scope.lastLimit = limit
					$scope.lastSort = sort
					$scope.lastFilter = filter
				)

			when ScreenWidget.DATA_SOURCE_TYPE['Fixed'].value
				$scope.collection = dataSource['collection']
				$meteor.autorun($scope, ->
					collection = $scope.getReactively('collection', true)
					filter =
						'_id': {'$in': collection}
						'environment_id': $rootScope.environment['_id']
						'document_schema_id': $scope.documentSchema['_id']

					startedAt = Date.now()
					$scope.loading = true
					$scope.loadingStartedAt = startedAt
					$scope.shouldShowLoadingTimeout = false
					$timeout(->
						if $scope.loading is true and $scope.loadingStartedAt is startedAt
							$scope.shouldShowLoadingTimeout = true
					, $scope.LOADING_TIMEOUT)

					$scope.$meteorSubscribe('Documents', filter)
						.then ->
							allDocuments = Document.db.find(filter).fetch()
							collectionDocuments = []
							collection.forEach (id) ->
								document = _.find(allDocuments, {'_id': id})
								document = angular.copy(document)
								collectionDocuments.push(document)
							$scope.documents = collectionDocuments
						.catch (error) ->
							$scope.error = true
							console.error(error)
						.finally ->
							$scope.loading = false
				)
	]
	link: ($scope, $element) ->
		$scope.$on('SORT_UPDATED', (event, sort) ->
			$scope.sort = sort
			$scope.limit = $scope.INITIAL_LIMIT
			$('.table-scroll', $element).scrollTop(0)
			event.stopPropagation()
		)

		$scope.$on('FILTER_UPDATED', (event, filter) ->
			$scope.filter = filter
			$scope.limit = $scope.INITIAL_LIMIT
			$('.table-scroll', $element).scrollTop(0)
			event.stopPropagation()
		)
])
