;['beforeEach', 'afterEach'].forEach((name) => {
  const originalFunction = global[name]
  global[name] = function (fn) {
    originalFunction(() => {
      const result = fn()
      if (result instanceof Promise) {
        waitsForPromise(() => result)
      }
    })
  }
})

;['it', 'fit', 'ffit', 'fffit'].forEach((name) => {
  const originalFunction = global[name]
  global[name] = function (description, fn) {
    originalFunction(description, () => {
      const result = fn()
      if (result instanceof Promise) {
        waitsForPromise(() => result)
      }
    })
  }
})

exports.timeoutPromise = function timeoutPromise (timeout) {
  return new Promise((resolve) => global.setTimeout(resolve, timeout))
}

exports.conditionPromise = async function conditionPromise (condition) {
  const startTime = Date.now()

  while (true) {
    await exports.timeoutPromise(100)

    if (await condition()) {
      return
    }

    if (Date.now() - startTime > 5000) {
      throw new Error('Timed out waiting on condition')
    }
  }
}

function waitsForPromise (fn) {
  const promise = fn()
  global.waitsFor('spec promise to resolve', function (done) {
    promise.then(done, function (error) {
      jasmine.getEnv().currentSpec.fail(error)
      done()
    })
  })
}
