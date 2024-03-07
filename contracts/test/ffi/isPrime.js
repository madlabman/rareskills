/**
 * @param {Number} n
 * @return {Boolean}
 */
function isPrime(n) {
  if (isNaN(n) || !isFinite(n) || n % 1 || n < 2) return false;
  var m = Math.sqrt(n); //returns the square root of the passed value
  for (var i = 2; i <= m; i++) if (n % i == 0) return false;
  return true;
}

function encodeBool(b) {
  return b
    ? "0x0000000000000000000000000000000000000000000000000000000000000001"
    : "0x0000000000000000000000000000000000000000000000000000000000000000";
}

const arg = Number.parseInt(process.argv[2]);
process.stdout.write(encodeBool(isPrime(arg)));
