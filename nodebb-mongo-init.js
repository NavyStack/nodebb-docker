db.createUser({
  user: 'mongodb-user',
  pwd: '3WbXE0W67LUNHVXZEjjiWSs6VKrpzU',
  roles: [
    { role: 'readWrite', db: 'nodebb' },
    { role: 'clusterMonitor', db: 'admin' }
  ]
})
