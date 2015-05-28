angular.module('app-factory').directive('afAttributeDateFilter', [() ->
	restrict: 'E'
	templateUrl: 'client/components/attributes/date/attribute-date-filter.template.html'
	replace: true
	scope:
		'attribute': 	'='
		'filterValue': 	'='		
	link: ($scope) ->

		key = "data.#{$scope.attribute['id']}"

		$scope.operatorOptions = ['on', 'before', 'after', 'between']
		$scope.operator = null
		$scope.value1 = null
		$scope.value2 = null

		$scope.calendarFormat = 'shortDate'
		$scope.calendar1IsOpen = false
		$scope.calendar2IsOpen = false

		$scope.openCalendar1 = (event) ->
			event.preventDefault()
			event.stopPropagation()
			$scope.calendar1IsOpen = true
			$scope.calendar2IsOpen = false

		$scope.openCalendar2 = (event) ->
			event.preventDefault()
			event.stopPropagation()
			$scope.calendar1IsOpen = false
			$scope.calendar2IsOpen = true

		$scope.hasValue = ->
			return true if $scope.calendar1IsOpen
			return true if $scope.calendar2IsOpen
			return true if $scope.value1 isnt null
			return true if $scope.value2 isnt null
			return true if $scope.operator isnt null
			return false

		$scope.shouldShowValue2 = ->
			return true if $scope.operator is 'between'
			return false

		$scope.clear = ->
			$scope.value1 = null
			$scope.value2 = null
			$scope.operator = null
			$scope.calendar1IsOpen = false
			$scope.calendar2IsOpen = false
			delete $scope.filterValue[key]

		$scope.updateFilterValue = ->
			value1 = try Date.parse($scope.value1).valueOf() if $scope.value1?
			value2 = try Date.parse($scope.value2).valueOf() if $scope.value2?
			operator = $scope.operator

			if not operator? and value1?
				$scope.operator = operator = 'on'

			if not $scope.shouldShowValue2() and value2?
				$scope.value2 = value2 = null
			
			$scope.filterValue[key] = switch operator
				when 'on' then value1
				when 'before' then {'$lt': value1}
				when 'after' then {'$gt': value1}
				when 'between' then {'$gt': value1, '$lt': value2}

		$scope.$watch('filterValue', ->
			if not $scope.filterValue? or not $scope.filterValue.hasOwnProperty(key)
				$scope.operator = null
				$scope.value1 = null
				$scope.value2 = null
				return

			value = $scope.filterValue[key]
			if _.isObject(value)
				lessThan = value['$lt']
				greaterThan = value['$gt']
				if lessThan? and greaterThan?
					$scope.operator = 'between'
					$scope.value1 = greaterThan
					$scope.value2 = lessThan
				else if lessThan?
					$scope.operator = 'before'
					$scope.value1 = lessThan
				else if greaterThan?
					$scope.operator = 'after'
					$scope.value1 = greaterThan
			else
				$scope.value = value
				$scope.operator = 'on'
		)
])