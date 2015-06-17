RoutineService.registerTemplate
	'name': 'variable'
	'label': 'Variable'
	'description': "Defines a variable for a value"
	'color': '#837a9f'
	'display_order': 600
	'size': {height: 50, width: 130}
	'type': RoutineService.SERVICE_TYPE['Data'].value
	'configuration': 
		'name': ''
	'nodes': [
		{
			name: 'value'
			type: RoutineService.NODE_TYPE['Input'].value
			position: 'Left'
		}
		{
			name: 'output'
			type: RoutineService.NODE_TYPE['Output'].value
			position: 'Right'
		}
	]

	describeConfiguration: (service) ->
		return "Name"

	execute: ({service}) ->
		throw new Meteor.Error('validation', "Define Variable service does not have any inputs") unless service.inputs?
		throw new Meteor.Error('validation', "Define Variable service does not have a 'value' input") unless service.inputs.hasOwnProperty('value')
		throw new Meteor.Error('validation', "Define Variable service does not have a configuration") unless service.configuration?
		
		value =
			name: service.configuration['name']				
			value: service.inputs['value']

		return [{node: 'output', value: value}]