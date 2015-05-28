angular.module('app-factory').directive('afAttributeTextFilter', [() ->
	restrict: 'E'
	templateUrl: 'client/components/attributes/text/attribute-text-filter.template.html'
	replace: true
	scope:
		'attribute': 	'='
		'filterValue': 	'='		
	link: ($scope) ->

		key = "data.#{$scope.attribute['id']}"

		$scope.operatorOptions = ['is', 'contains']
		$scope.operator = null
		$scope.value = null

		$scope.hasValue = ->
			return true if $scope.value isnt null
			return true if $scope.operator isnt null
			return false

		$scope.clear = ->
			$scope.value = null
			$scope.operator = null
			delete $scope.filterValue[key]

		$scope.updateFilterValue = ->
			value = $scope.value
			operator = $scope.operator

			if not operator? and value?
				$scope.operator = operator = 'is'

			$scope.filterValue[key] = switch operator
				when 'is' then "#{value}"
				when 'contains' then {'$regex': "#{value}", '$options': 'i'}

		$scope.$watch('filterValue', ->
			if $scope.filterValue is null or not $scope.filterValue.hasOwnProperty(key)
				$scope.operator = null
				$scope.value = null
				return

			value = $scope.filterValue[key]
			if _.isObject(value)
				if value['$regex']?
					$scope.operator = 'contains'
					$scope.value = value['$regex']
			else
				$scope.value = value
				$scope.operator = 'is'
		)
])