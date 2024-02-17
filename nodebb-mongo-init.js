db.createUser({
  user: 'askfront-mongo',
  pwd: 'xMxK4JX2GINcIUYKnLVFbUOq0WeqbB',
  roles: [
    { role: 'readWrite', db: 'askfront-mongo' },
    { role: 'clusterMonitor', db: 'admin' }
  ]
})
