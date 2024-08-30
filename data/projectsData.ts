interface Project {
  title: string,
  description: string,
  href?: string,
  imgSrc?: string,
}

const projectsData: Project[] = [
  {
    title: 'Coming soon',
    description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Nisi porro quas provident quo asperiores veniam cupiditate tenetur amet odit ut!`,
    imgSrc: '/static/images/coming-soon.png',
    href: '#',
  },
]

export default projectsData
