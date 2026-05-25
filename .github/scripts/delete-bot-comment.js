module.exports = async ({ github, context }) => {
  const commentId = parseInt(process.env.COMMENT_ID, 10);
  if (commentId) {
    await github.rest.issues.deleteComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: commentId,
    });
    console.log(`Deleted comment #${commentId}`);
  }
};
