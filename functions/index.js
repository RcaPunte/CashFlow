const cors = require("cors")({ origin: true });

exports.supabaseLogin = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { email, password } = req.body;

      const response = await fetch(
        "https://xqpyswjocnbsfvmsjdqn.supabase.co/auth/v1/token?grant_type=password",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxcHlzd2pvY25ic2Z2bXNqZHFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjY3NjYsImV4cCI6MjA3OTc0Mjc2Nn0.YTl4Pf3cM0JmTa5t0I0pE5iKnUfHaGD_h5iXhP1Iy50',
          },
          body: JSON.stringify({
            email,
            password
          })
        }
      );

      const data = await response.json();
      res.status(response.status).send(data);

    } catch (error) {
      res.status(500).send({ error: error.message });
    }
  });
});