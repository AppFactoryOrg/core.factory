Meteor.publish 'Document', (document_id) ->
	return Document.db.find('_id': document_id)

Meteor.publishComposite 'Documents', (filter, paging) ->
	throw new Error('Filter parameter is required') unless filter?
	throw new Error('Filter parameter requires environment_id attribute') unless filter['environment_id']?
	throw new Error('Filter parameter requires document_schema_id attribute') unless filter['document_schema_id']?

	documentSchema = DocumentSchema.db.findOne(filter['document_schema_id'])
	childDocumentAttributesId = _.pluck(_.filter(documentSchema['attributes'], {'data_type': DocumentAttribute.DATA_TYPE['Document'].value}), 'id')

	return { 
		find: ->
			paging = {'limit': Config['MAX_TABLE_RECORDS']} unless paging?
			paging['limit'] = Config['MAX_TABLE_RECORDS'] if paging['limit'] > Config['MAX_TABLE_RECORDS']
			return Document.db.find(filter, paging)

		children: [
			{
				find: (document) ->
					childDocumentIds = _.values(_.pick(document['data'], childDocumentAttributesId))
					return if _.isEmpty(childDocumentIds)
					return Document.db.find({'_id': {'$in': childDocumentIds}})
			}
		]
	}