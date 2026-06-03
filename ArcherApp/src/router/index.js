import { createRouter, createWebHistory } from 'vue-router'
import Home from '../Home.vue'
import UseCase2 from '../UseCase2.vue'
import UseCase3 from '../UseCase3.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/usecase2', name: 'UseCase2', component: UseCase2 },
  { path: '/usecase3', name: 'UseCase3', component: UseCase3 }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
