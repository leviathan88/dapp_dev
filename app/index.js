const express = require('express')
const app = express()

app.use(express.static('src'))
app.use(express.static('../app-contracts/build/contracts'))

app.get('/', (req, res) => {
  res.render('index.html')
})

app.listen(3000, () => {
  console.log("app is running")
})