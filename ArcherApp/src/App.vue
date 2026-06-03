<template>
  <div>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
      <div class="container">
        <a class="navbar-brand" href="#">ArcherApp</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto mb-2 mb-lg-0">
            <li class="nav-item">
              <RouterLink class="nav-link" to="/">Use Case 1</RouterLink>
            </li>
            <li class="nav-item">
              <RouterLink class="nav-link" to="/usecase2">Use Case 2</RouterLink>
            </li>
            <li class="nav-item">
              <RouterLink class="nav-link" to="/usecase3">Use Case 3</RouterLink>
            </li>
          </ul>
        </div>
      </div>
    </nav>

    <router-view />
  </div>
</template>

<script setup>
import { RouterLink } from 'vue-router'
</script>

<style>
.navbar { margin-bottom: 1rem }
</style>
