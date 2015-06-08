Meteor.publish 'Users', ({application_id}) ->
	filters = 
		'profile.application_roles.application_id': application_id

	fields = 
		'profile': 1
		'emails': 1

	return User.db.find(filters, {fields})