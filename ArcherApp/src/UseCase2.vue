<template>
  <div class="container py-4" style="max-width:600px">
    <h1 class="mb-4 text-center">Score Approval</h1>

    <div class="card p-3 mb-3">
	  <div>
        <label class="form-label fw-semibold"></label>
	    <label v-for="s in scores" :key="s.RecordID">
		ID={{ s.RecordID }} | Preliminary={{ s.PrelimTotal }}
		  <input
          type="number"
		  step="1"
          :value="s.PrelimTotal" 
          class="score-input"
          />
		  <button @click="submitScore(s.RecordID, $event.target.previousElementSibling.value)">Approve</button>
		</label>
	  </div>
	</div>
  </div>
</template>


<script setup>
import { ref, computed, onMounted } from 'vue'

const scores = ref([])
const selectedScore = ref(null)

const currentScore = computed(() => scores.value.find(s => s.RecordID === selectedScore.value))

const fetchUnapprovedScores = async () => {
  const res = await fetch('api/get_unapproved_scores')
  scores.value = await res.json()
}


const submitScore = async (record_id, official_score) => {

  official_score = Math.floor(official_score)
  console.log("submitting instructor score: ", record_id, official_score)
  
  const res = await fetch('/api/submit_instructor_score', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      OfficialTotal: official_score,
      RecordID: record_id
	})
  })
  if (!res.ok) return alert('Failed to start session')
  const data = await res.json()
  
  scores.value = scores.value.filter(s => s.RecordID !== record_id)
}

onMounted(async () => {
  await Promise.all([fetchUnapprovedScores()])
})
</script>
