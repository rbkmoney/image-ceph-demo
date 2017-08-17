#!groovy
// -*- mode: groovy -*-
build('image-ceph-demo', 'docker-host') {
  checkoutRepo()
  withCredentials(
    [[$class: 'FileBinding', credentialsId: 'github-rbkmoney-ci-bot-file', variable: 'GITHUB_PRIVKEY'],
     [$class: 'FileBinding', credentialsId: 'bakka-su-rbkmoney-all', variable: 'BAKKA_SU_PRIVKEY']]) {
    runStage('submodules') {
      sh 'make -j4 submodules'
    }
  }
  withCredentials(
    [[$class: 'FileBinding', credentialsId: 'github-rbkmoney-ci-bot-file', variable: 'GITHUB_PRIVKEY']]) {
    runStage('ceph-demo image build') {
      sh 'make'
    }
  }
  try {
    if (env.BRANCH_NAME == 'master') {
      runStage('docker image push') {
	sh 'make push'
      }
      
    }
  } finally {
    runStage('rm local image') {
      sh 'make clean'
    }
  }
}
