db.createUser({
  user: 'navystack-mongo',
  pwd: 'lyFn5aQepK5Q8e6o6GC5HgvWktE2vb',
  roles: [
    { role: 'readWrite', db: 'navystack-mongo' },
    { role: 'clusterMonitor', db: 'admin' }
  ]
})
